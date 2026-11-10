const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
}

const PROJECT_ID = 'prm393-final-test';

describe('Cloud Firestore Security Rules (Appendix B Verification)', () => {
  let testEnv;
  let systemDb;
  let userDb;
  let staffDb;
  let adminDb;
  let otherUserDb;
  let unauthedDb;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
      },
    });

    // Create system DB context once to bypass rules for seeding
    systemDb = testEnv.createContext('owner').firestore();

    // Create test user contexts once to prevent re-initialization crashes
    userDb = testEnv.authenticatedContext('user_123').firestore();
    staffDb = testEnv.authenticatedContext('staff_1').firestore();
    adminDb = testEnv.authenticatedContext('admin_1').firestore();
    otherUserDb = testEnv.authenticatedContext('user_456').firestore();
    unauthedDb = testEnv.unauthenticatedContext().firestore();
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // R-01: users - user creates own profile on first sign-in with role = 'user' -> Allowed
  it('R-01: user can create personal profile with role = "user"', async () => {
    await assertSucceeds(
      userDb.collection('users').doc('user_123').set({
        uid: 'user_123',
        email: 'user123@fpt.edu.vn',
        displayName: 'Student One',
        role: 'user',
        createdAt: new Date(),
      })
    );
  });

  // R-02: users - user self-updates own role to 'admin' -> Denied
  it('R-02: user cannot escalate own role to "admin"', async () => {
    await systemDb.collection('users').doc('user_123').set({
      uid: 'user_123',
      email: 'user123@fpt.edu.vn',
      role: 'user',
      displayName: 'Student One',
    });

    await assertFails(
      userDb.collection('users').doc('user_123').update({
        role: 'admin',
      })
    );
  });

  // R-03: users - admin updates role of another user to 'staff' -> Allowed
  it('R-03: admin can update role of another user to "staff"', async () => {
    await systemDb.collection('users').doc('admin_1').set({
      uid: 'admin_1',
      email: 'admin@fpt.edu.vn',
      role: 'admin',
    });
    await systemDb.collection('users').doc('user_123').set({
      uid: 'user_123',
      email: 'user123@fpt.edu.vn',
      role: 'user',
    });

    await assertSucceeds(
      adminDb.collection('users').doc('user_123').update({
        role: 'staff',
      })
    );
  });

  // R-04: courses - user reads course with status == 'published' -> Allowed
  it('R-04: user can read courses with status == "published"', async () => {
    await systemDb.collection('users').doc('user_123').set({
      uid: 'user_123',
      role: 'user',
    });
    await systemDb.collection('courses').doc('PRM392').set({
      id: 'PRM392',
      code: 'PRM392',
      name: 'Mobile Programming',
      credits: 3,
      status: 'published',
    });
    await systemDb.collection('courses').doc('DRAFT101').set({
      id: 'DRAFT101',
      code: 'DRAFT101',
      name: 'Draft Course',
      credits: 2,
      status: 'draft',
    });

    await assertSucceeds(userDb.collection('courses').doc('PRM392').get());
    await assertFails(userDb.collection('courses').doc('DRAFT101').get());
  });

  // R-05: courses - user creates or updates course -> Denied
  it('R-05: regular user cannot create or update courses', async () => {
    await systemDb.collection('users').doc('user_123').set({
      uid: 'user_123',
      role: 'user',
    });
    await systemDb.collection('courses').doc('PRM392').set({
      id: 'PRM392',
      code: 'PRM392',
      name: 'Mobile Programming',
      credits: 3,
      status: 'published',
    });

    await assertFails(
      userDb.collection('courses').doc('SWP391').set({
        code: 'SWP391',
        name: 'Software Project',
        credits: 3,
        status: 'published',
      })
    );
    await assertFails(
      userDb.collection('courses').doc('PRM392').update({
        name: 'Hacked Course Name',
      })
    );
  });

  // R-06: courses - staff or admin creates/updates course with name.size() <= 120 -> Allowed
  it('R-06: staff or admin can create / update course with name.size() <= 120', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });

    await assertSucceeds(
      staffDb.collection('courses').doc('PRM392').set({
        code: 'PRM392',
        name: 'Mobile Development with Flutter',
        credits: 3,
        status: 'published',
      })
    );
  });

  // R-07: courses - staff deletes a course -> Denied
  it('R-07: staff cannot hard delete a course', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });
    await systemDb.collection('courses').doc('PRM392').set({
      code: 'PRM392',
      name: 'Mobile Programming',
      credits: 3,
      status: 'published',
    });

    await assertFails(staffDb.collection('courses').doc('PRM392').delete());
  });

  // R-07B: courses - admin deletes a course -> Allowed
  it('R-07B: admin can hard delete a course', async () => {
    await systemDb.collection('users').doc('admin_1').set({
      uid: 'admin_1',
      role: 'admin',
    });
    await systemDb.collection('courses').doc('PRM392').set({
      code: 'PRM392',
      name: 'Mobile Programming',
      credits: 3,
      status: 'published',
    });

    await assertSucceeds(adminDb.collection('courses').doc('PRM392').delete());
  });

  // R-08: study_plans - user creates own plan with status == 'pending' -> Allowed
  it('R-08: user can create own study plan with status == "pending"', async () => {
    await assertSucceeds(
      userDb.collection('study_plans').doc('plan_1').set({
        userId: 'user_123',
        status: 'pending',
        semesterName: 'Fall 2026',
        totalCredits: 12,
      })
    );
  });

  // R-09: study_plans - user creates plan with status == 'approved' (self-approve) -> Denied
  it('R-09: user cannot create own plan with status == "approved"', async () => {
    await assertFails(
      userDb.collection('study_plans').doc('plan_1').set({
        userId: 'user_123',
        status: 'approved',
        semesterName: 'Fall 2026',
        totalCredits: 12,
      })
    );
  });

  // R-10: study_plans - staff updates plan from 'pending' -> 'approved' with reviewReason -> Allowed
  it('R-10: staff can update plan from "pending" to "approved" with reviewReason', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });
    await systemDb.collection('study_plans').doc('plan_1').set({
      userId: 'user_123',
      status: 'pending',
      semesterName: 'Fall 2026',
    });

    await assertSucceeds(
      staffDb.collection('study_plans').doc('plan_1').update({
        status: 'approved',
        reviewReason: 'Lộ trình 22h cân bằng, đủ môn tiên quyết',
        reviewedBy: 'advisor@fpt.edu.vn',
      })
    );
  });

  // R-11: announcements - user creates new announcement -> Denied
  it('R-11: regular user cannot create announcement', async () => {
    await systemDb.collection('users').doc('user_123').set({
      uid: 'user_123',
      role: 'user',
    });

    await assertFails(
      userDb.collection('announcements').doc('ann_1').set({
        title: 'Học bổng kỳ tới',
        status: 'published',
      })
    );
  });

  // R-12: announcements - staff creates new announcement with status == 'published' -> Allowed
  it('R-12: staff can create announcement with status == "published"', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });

    await assertSucceeds(
      staffDb.collection('announcements').doc('ann_1').set({
        title: 'Thông báo mở đăng ký môn chuyên ngành Fall 2026',
        status: 'published',
        createdAt: new Date(),
      })
    );
  });

  // Students collection verification & Staff/Admin sync on acceptance
  it('Students: student can read & write own profile, staff/admin can read & sync grades, other user denied', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });
    await systemDb.collection('users').doc('user_456').set({
      uid: 'user_456',
      role: 'user',
    });

    // Student creates own profile
    await assertSucceeds(
      userDb.collection('students').doc('user_123').set({
        uid: 'user_123',
        fullName: 'Nguyen Van A',
        studentId: 'SE123456',
        currentGpa: 3.5,
      })
    );

    // Student creates completed_courses
    await assertSucceeds(
      userDb.collection('students').doc('user_123').collection('completed_courses').doc('PRM392').set({
        code: 'PRM392',
        grade: 8.5,
        isPassed: true,
      })
    );

    // Staff can read student profile and subcollection
    await assertSucceeds(
      staffDb.collection('students').doc('user_123').get()
    );
    await assertSucceeds(
      staffDb.collection('students').doc('user_123').collection('completed_courses').doc('PRM392').get()
    );

    // Staff can sync approved grades into student's profile & completed_courses
    await assertSucceeds(
      staffDb.collection('students').doc('user_123').update({
        accumulatedCredits: 30,
        currentGpa: 3.65,
        passedCourseCodes: ['PRM392', 'SWP391'],
      })
    );
    await assertSucceeds(
      staffDb.collection('students').doc('user_123').collection('completed_courses').doc('SWP391').set({
        code: 'SWP391',
        grade: 9.0,
        isPassed: true,
      })
    );

    // Another student cannot read or write
    await assertFails(
      otherUserDb.collection('students').doc('user_123').get()
    );
    await assertFails(
      otherUserDb.collection('students').doc('user_123').collection('completed_courses').doc('PRM392').get()
    );
    await assertFails(
      otherUserDb.collection('students').doc('user_123').update({
        currentGpa: 4.0,
      })
    );
    await assertFails(
      otherUserDb.collection('students').doc('user_123').collection('completed_courses').doc('PRM392').delete()
    );
  });

  // Stage 2 Approval Tests:
  it('Study Plans (Stage 2): user can create plan with pending_acceptance status', async () => {
    await assertSucceeds(
      userDb.collection('study_plans').doc('plan_stage2').set({
        userId: 'user_123',
        status: 'pending_acceptance',
        semesterName: 'Fall 2026',
        totalCredits: 12,
      })
    );
  });

  it('Study Plans (Stage 2): user can submit approved plan for acceptance, cannot self-complete', async () => {
    await systemDb.collection('study_plans').doc('plan_approved').set({
      userId: 'user_123',
      status: 'approved',
      semesterName: 'Fall 2026',
    });

    // Student submits for acceptance
    await assertSucceeds(
      userDb.collection('study_plans').doc('plan_approved').update({
        status: 'pending_acceptance',
      })
    );

    // Student cannot self-complete plan
    await assertFails(
      userDb.collection('study_plans').doc('plan_approved').update({
        status: 'completed',
      })
    );
  });

  it('Study Plans (Stage 2): staff can complete or reject acceptance with reviewReason', async () => {
    await systemDb.collection('users').doc('staff_1').set({
      uid: 'staff_1',
      role: 'staff',
    });
    await systemDb.collection('study_plans').doc('plan_pending_acc').set({
      userId: 'user_123',
      status: 'pending_acceptance',
      semesterName: 'Fall 2026',
    });

    // Staff approves acceptance to completed with reviewReason
    await assertSucceeds(
      staffDb.collection('study_plans').doc('plan_pending_acc').update({
        status: 'completed',
        reviewReason: 'Điểm số hợp lệ, hoàn thành nghiệm thu kỳ học',
        reviewedBy: 'advisor@fpt.edu.vn',
      })
    );

    // Reset status to pending_acceptance
    await systemDb.collection('study_plans').doc('plan_pending_acc').update({
      status: 'pending_acceptance',
    });

    // Staff rejects acceptance with reviewReason
    await assertSucceeds(
      staffDb.collection('study_plans').doc('plan_pending_acc').update({
        status: 'acceptance_rejected',
        reviewReason: 'Bảng điểm chưa có chữ ký xác nhận của phòng đào tạo',
        reviewedBy: 'advisor@fpt.edu.vn',
      })
    );

    // Staff update fails without valid reviewReason
    await assertFails(
      staffDb.collection('study_plans').doc('plan_pending_acc').update({
        status: 'completed',
        reviewReason: 'ok', // < 3 characters
      })
    );
  });

  it('Study Plans (Resubmission): user can modify approved plan and resubmit to pending', async () => {
    await systemDb.collection('study_plans').doc('plan_approved_modify').set({
      userId: 'user_123',
      status: 'approved',
      semesterName: 'Fall 2026',
      totalCredits: 12,
    });

    // Student modifies the plan (e.g. adds course) and resubmits to pending
    await assertSucceeds(
      userDb.collection('study_plans').doc('plan_approved_modify').update({
        status: 'pending',
        totalCredits: 15,
      })
    );
  });

  // System Settings Tests (match /system_settings/{id})
  describe('System Settings (system_settings/{id})', () => {
    it('allows authenticated student to read system_settings/workload_config', async () => {
      await systemDb.collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
      await systemDb.collection('system_settings').doc('workload_config').set({
        maxSafeWorkloadHours: 25,
        updatedBy: 'staff_1',
      });

      await assertSucceeds(
        userDb.collection('system_settings').doc('workload_config').get()
      );
    });

    it('denies unauthenticated user from reading system_settings/workload_config', async () => {
      await systemDb.collection('system_settings').doc('workload_config').set({
        maxSafeWorkloadHours: 25,
      });

      await assertFails(
        unauthedDb.collection('system_settings').doc('workload_config').get()
      );
    });

    it('allows staff or admin to create and update system_settings/workload_config with valid hours', async () => {
      await systemDb.collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await systemDb.collection('users').doc('admin_1').set({
        uid: 'admin_1',
        role: 'admin',
      });

      // Staff creates workload_config with valid hours
      await assertSucceeds(
        staffDb.collection('system_settings').doc('workload_config').set({
          maxSafeWorkloadHours: 30,
          updatedBy: 'staff_1',
          updatedAt: new Date(),
        })
      );

      // Admin updates workload_config with valid hours
      await assertSucceeds(
        adminDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: 40,
          updatedBy: 'admin_1',
          updatedAt: new Date(),
        })
      );
    });

    it('denies regular student from creating or updating system_settings/workload_config', async () => {
      await systemDb.collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
      await systemDb.collection('system_settings').doc('workload_config').set({
        maxSafeWorkloadHours: 25,
      });

      // Student cannot update
      await assertFails(
        userDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: 35,
        })
      );

      // Student cannot set/create
      await assertFails(
        userDb.collection('system_settings').doc('workload_config').set({
          maxSafeWorkloadHours: 35,
        })
      );
    });

    it('rejects invalid maxSafeWorkloadHours (negative, < 10, > 60, or non-numeric)', async () => {
      await systemDb.collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await systemDb.collection('system_settings').doc('workload_config').set({
        maxSafeWorkloadHours: 25,
      });

      // Negative hours
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: -5,
        })
      );

      // Hours < 10
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: 9,
        })
      );

      // Hours > 60
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: 65,
        })
      );

      // Non-numeric hours
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').update({
          maxSafeWorkloadHours: 'invalid',
        })
      );

      // updatedBy > 100 chars
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').update({
          updatedBy: 'a'.repeat(101),
        })
      );
    });

    it('disallows deletion of system_settings documents by any role', async () => {
      await systemDb.collection('users').doc('admin_1').set({
        uid: 'admin_1',
        role: 'admin',
      });
      await systemDb.collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await systemDb.collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
      await systemDb.collection('system_settings').doc('workload_config').set({
        maxSafeWorkloadHours: 25,
      });

      // Admin cannot delete
      await assertFails(
        adminDb.collection('system_settings').doc('workload_config').delete()
      );

      // Staff cannot delete
      await assertFails(
        staffDb.collection('system_settings').doc('workload_config').delete()
      );

      // Student cannot delete
      await assertFails(
        userDb.collection('system_settings').doc('workload_config').delete()
      );
    });
  });
});
