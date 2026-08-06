# Triage Summary - T-1001

## Summary (one line)
New Windows 11 laptop is requesting a BitLocker recovery key on every boot.

## Impact (who/how many/business urgency)
- Who is affected: Single reported user on a new Win11 laptop (to-verify).
- How many are affected: 1 reported device/user currently; wider scope unknown (to-verify).
- Business urgency: Medium to High (to-verify) due to repeated startup disruption and potential user lockout risk if recovery key is unavailable.

## Known Facts
- Ticket reference: T-1001.
- Device type: New Windows 11 laptop.
- Symptom: BitLocker recovery key prompt appears at every boot.

## Missing Information to Gather
- User identity and contact method for live troubleshooting (to-verify).
- Exact device identifier/asset tag and serial number (to-verify).
- Whether user can successfully enter recovery key and continue to Windows each time (to-verify).
- Whether the behavior started from first boot or after a specific change (BIOS/UEFI update, firmware update, docking/peripheral change, hardware swap) (to-verify).
- Whether Secure Boot/TPM related alerts are visible in BIOS/UEFI or Windows event logs (to-verify).
- Whether this is isolated or seen on other newly issued laptops of same model/build (to-verify).
- Recovery key escrow location/availability in approved internal tooling (to-verify).

## Likely Category
Endpoint Security - BitLocker Recovery Loop (to-verify).

## First Diagnostic Step
Confirm the user can boot by entering the recovery key, then immediately collect baseline evidence: exact timestamp of prompt, last change made before issue started, and whether any BIOS/UEFI or hardware state changed since build/issue.
