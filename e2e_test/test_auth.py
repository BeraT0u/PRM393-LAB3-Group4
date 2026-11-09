"""
ARTEMIS E2E Test Suite: Authentication & User Profiles (TC-01, TC-02, TC-12)
"""

import pytest

@pytest.mark.asyncio
async def test_artemis_google_sign_in_happy_path(artemis_client):
    """TC-01: Sign in with Google account and verify landing on Home with profile loaded."""
    instruction = (
        "Launch the EduPlan app from the home screen. On the login screen SCR-01, "
        "tap the 'Đăng nhập với Google' button. In the account picker, select test account "
        "student_se180504@fpt.edu.vn. Return the student name and user ID shown on the Home screen."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
    assert result.extracted_values.get("user_name") == "Trần Hoàng Long"
    assert result.extracted_values.get("user_id") == "student_se180504"

@pytest.mark.asyncio
async def test_artemis_sign_out(artemis_client):
    """TC-12: Sign out and verify return to login screen."""
    instruction = (
        "From the Profile screen SCR-08, tap 'Đăng xuất', then confirm the logout dialog. "
        "Verify that the app returns to the Login screen SCR-01 with Google sign-in button visible."
    )
    result = await artemis_client.execute_instruction(instruction)
    assert result.status == "SUCCESS"
