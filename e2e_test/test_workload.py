"""
ARTEMIS E2E Test Suite: Workload Analyzer, Conflict Blocking & Resolution (TC-06, TC-07, TC-08)
"""

import pytest

@pytest.mark.asyncio
async def test_artemis_workload_overload_blocks_save(artemis_client):
    """TC-06: 34h study plan triggers warning and blocks save button."""
    instruction = (
        "Open Plan Analyzer screen SCR-06A with 4 registered courses totaling 34h/week self-study. "
        "Return the workload hours value, the warning indicator color/state, and whether 'Lưu kế hoạch' is enabled."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
    assert result.extracted_values.get("workload_hours") == 34.0
    assert result.extracted_values.get("warning_state") == "OVERLOAD_RED"
    assert result.extracted_values.get("save_button_enabled") is False

@pytest.mark.asyncio
async def test_artemis_resolve_conflict_unblocks_save(artemis_client):
    """TC-08: Swapping IAE201 for PRM323 reduces load to 26h and unblocks save."""
    instruction = (
        "On Selected Courses screen SCR-06B, tap 'Đổi môn khác' next to course IAE201. "
        "Select course PRM323 from the filtered catalog. Return the updated workload hours and save button state."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
    assert result.extracted_values.get("workload_hours") == 26.0
    assert result.extracted_values.get("save_button_enabled") is True
