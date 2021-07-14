/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * Copyright (C) 2013 Citrix Systems
 *
 * Author: Stefano Stabellini <stefano.stabellini@eu.citrix.com>
 */

#define pr_fmt(fmt) "arm-pv: " fmt

#include <linux/arm-smccc.h>
#include <linux/cpuhotplug.h>
#include <linux/export.h>
#include <linux/io.h>
#include <linux/jump_label.h>
#include <linux/printk.h>
#include <linux/psci.h>
#include <linux/types.h>
#include <asm/paravirt.h>
#include <asm/pvsched-abi.h>
#include <asm/qspinlock_paravirt.h>

#define CREATE_TRACE_POINTS
#include "trace-paravirt.h"

struct static_key paravirt_steal_enabled;
struct static_key paravirt_steal_rq_enabled;

struct paravirt_patch_template pv_ops = {
#ifdef CONFIG_PARAVIRT_SPINLOCKS
	.sched.queued_spin_lock_slowpath	= native_queued_spin_lock_slowpath,
	.sched.queued_spin_unlock		= native_queued_spin_unlock,
#endif
	.sched.vcpu_is_preempted		= __native_vcpu_is_preempted,
};
EXPORT_SYMBOL_GPL(pv_ops);

DEFINE_PER_CPU(struct pvsched_vcpu_state, pvsched_vcpu_region) __aligned(64);
EXPORT_PER_CPU_SYMBOL(pvsched_vcpu_region);

static bool kvm_vcpu_is_preempted(int cpu)
{
	struct pvsched_vcpu_state *reg;
	u32 preempted;

	reg = &per_cpu(pvsched_vcpu_region, cpu);
	if (!reg) {
		pr_warn_once("PV sched enabled but not configured for cpu %d\n",
			     cpu);
		return false;
	}

	preempted = le32_to_cpu(READ_ONCE(reg->preempted));

	return !!preempted;
}

static int pvsched_vcpu_state_dying_cpu(unsigned int cpu)
{
	struct pvsched_vcpu_state *reg;
	struct arm_smccc_res res;

	reg = this_cpu_ptr(&pvsched_vcpu_region);
	if (!reg)
		return -EFAULT;

	arm_smccc_1_1_invoke(ARM_SMCCC_HV_PV_SCHED_IPA_RELEASE, &res);
	memset(reg, 0, sizeof(*reg));

	return 0;
}

static int init_pvsched_vcpu_state(unsigned int cpu)
{
	struct pvsched_vcpu_state *reg;
	struct arm_smccc_res res;

	reg = this_cpu_ptr(&pvsched_vcpu_region);
	if (!reg)
		return -EFAULT;

	/* Pass the memory address to host via hypercall */
	arm_smccc_1_1_invoke(ARM_SMCCC_HV_PV_SCHED_IPA_INIT,
			     virt_to_phys(reg), &res);

	return 0;
}

static int kvm_arm_init_pvsched(void)
{
	int ret;

	ret = cpuhp_setup_state(CPUHP_AP_ARM_KVM_PVSCHED_STARTING,
				"hypervisor/arm/pvsched:starting",
				init_pvsched_vcpu_state,
				pvsched_vcpu_state_dying_cpu);

	if (ret < 0) {
		pr_warn("PV sched init failed\n");
		return ret;
	}

	return 0;
}

static bool has_kvm_pvsched(void)
{
	struct arm_smccc_res res;

	/* To detect the presence of PV sched support we require SMCCC 1.1+ */
	if (psci_ops.smccc_version < SMCCC_VERSION_1_1)
		return false;

	arm_smccc_1_1_invoke(ARM_SMCCC_ARCH_FEATURES_FUNC_ID,
			     ARM_SMCCC_HV_PV_SCHED_FEATURES, &res);

	return (res.a0 == SMCCC_RET_SUCCESS);
}

#ifdef CONFIG_PARAVIRT_SPINLOCKS
static bool arm_pvspin = false;

/* Kick a cpu by its cpuid. Used to wake up a halted vcpu */
static void kvm_kick_cpu(int cpu)
{
	struct arm_smccc_res res;

	arm_smccc_1_1_invoke(ARM_SMCCC_HV_PV_SCHED_KICK_CPU, cpu, &res);

	trace_kvm_kick_cpu("kvm kick cpu", smp_processor_id(), cpu);
}

static void kvm_wait(u8 *ptr, u8 val)
{
	unsigned long flags;

	if (in_nmi())
		return;

	local_irq_save(flags);

	if (READ_ONCE(*ptr) != val)
		goto out;

	dsb(sy);
	wfi();
	trace_kvm_wait("kvm wait wfi", smp_processor_id());

out:
	local_irq_restore(flags);
}

void __init pv_qspinlock_init(void)
{
	/* Don't use the PV qspinlock code if there is only 1 vCPU. */
	if (num_possible_cpus() == 1)
		arm_pvspin = false;

	if (!arm_pvspin) {
		pr_info("PV qspinlocks disabled\n");
		return;
	}
	pr_info("PV qspinlocks enabled\n");

	__pv_init_lock_hash();
	pv_ops.sched.queued_spin_lock_slowpath = __pv_queued_spin_lock_slowpath;
	pv_ops.sched.queued_spin_unlock = __pv_queued_spin_unlock;
	pv_ops.sched.wait = kvm_wait;
	pv_ops.sched.kick = kvm_kick_cpu;
}

static __init int arm_parse_pvspin(char *arg)
{
	arm_pvspin = true;
	return 0;
}
early_param("arm_pvspin", arm_parse_pvspin);
#endif  /* CONFIG_PARAVIRT_SPINLOCKS */

int __init pv_sched_init(void)
{
	int ret;

	if (is_hyp_mode_available())
		return 0;

	if (!has_kvm_pvsched()) {
		pr_warn("PV sched is not available\n");
		return 0;
	}

	ret = kvm_arm_init_pvsched();
	if (ret)
		return ret;

	pv_ops.sched.vcpu_is_preempted = kvm_vcpu_is_preempted;
	pr_info("using PV sched preempted\n");

	pv_qspinlock_init();

	return 0;
}
