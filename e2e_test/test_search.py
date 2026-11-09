"""
ARTEMIS E2E Test Suite: Course Search & Filtering (TC-03, TC-04)
"""

import pytest

@pytest.mark.asyncio
async def test_artemis_course_search_happy_path(artemis_client):
    """TC-03: Search course catalog for 'PRM' and verify results count."""
    instruction = (
        "Navigate to Course Catalog screen SCR-04 by tapping the Tra cứu icon on bottom navigation. "
        "Enter 'PRM' into the search input. Return the number of matching courses and their codes."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
    assert result.extracted_values.get("result_count") == 2
    assert "PRM392" in result.extracted_values.get("found_courses", "")

@pytest.mark.asyncio
async def test_artemis_course_search_empty_state_error_path(artemis_client):
    """TC-04: Search for non-existent course code and verify empty state."""
    instruction = (
        "On Course Catalog screen SCR-04, type 'XYZ999' into the search bar. "
        "Verify that an Empty State appears with Vietnamese message 'Không tìm thấy môn học phù hợp'."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
