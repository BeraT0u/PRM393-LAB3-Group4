"""
ARTEMIS E2E Test Suite: Semester Closure & PDF Report Export (TC-09, TC-10)
"""

import pytest

@pytest.mark.asyncio
async def test_artemis_pdf_export_and_upload(artemis_client):
    """TC-10: Export A4 study plan PDF and upload to Firebase Cloud Storage."""
    instruction = (
        "Navigate to Profile screen SCR-08. Tap 'Xuất báo cáo PDF A4'. "
        "Verify that file 'EduPlan_Study_Plan_Fall2024.pdf' is generated and uploaded successfully."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
    assert result.extracted_values.get("file_name") == "EduPlan_Study_Plan_Fall2024.pdf"
    assert result.extracted_values.get("upload_status") == "SUCCESS"
