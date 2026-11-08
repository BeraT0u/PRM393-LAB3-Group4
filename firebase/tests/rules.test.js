const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'prm393-final-test';

describe('Cloud Firestore Security Rules (Appendix B Verification)', () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
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
    const userDb = testEnv.authenticatedContext('user_123').firestore();
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user_123').set({
        uid: 'user_123',
        email: 'user123@fpt.edu.vn',
        role: 'user',
        displayName: 'Student One',
      });
    });

    const userDb = testEnv.authenticatedContext('user_123').firestore();
    await assertFails(
      userDb.collection('users').doc('user_123').update({
        role: 'admin',
      })
    );
  });

  // R-03: users - admin updates role of another user to 'staff' -> Allowed
  it('R-03: admin can update role of another user to "staff"', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('admin_1').set({
        uid: 'admin_1',
        email: 'admin@fpt.edu.vn',
        role: 'admin',
      });
      await context.firestore().collection('users').doc('user_123').set({
        uid: 'user_123',
        email: 'user123@fpt.edu.vn',
        role: 'user',
      });
    });

    const adminDb = testEnv.authenticatedContext('admin_1').firestore();
    await assertSucceeds(
      adminDb.collection('users').doc('user_123').update({
        role: 'staff',
      })
    );
  });

  // R-04: courses - user reads course with status == 'published' -> Allowed
  it('R-04: user can read courses with status == "published"', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
      await context.firestore().collection('courses').doc('PRM392').set({
        id: 'PRM392',
        code: 'PRM392',
        name: 'Mobile Programming',
        credits: 3,
        status: 'published',
      });
      await context.firestore().collection('courses').doc('DRAFT101').set({
        id: 'DRAFT101',
        code: 'DRAFT101',
        name: 'Draft Course',
        credits: 2,
        status: 'draft',
      });
    });

    const userDb = testEnv.authenticatedContext('user_123').firestore();
    await assertSucceeds(userDb.collection('courses').doc('PRM392').get());
    await assertFails(userDb.collection('courses').doc('DRAFT101').get());
  });

  // R-05: courses - user creates or updates course -> Denied
  it('R-05: regular user cannot create or update courses', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
      await context.firestore().collection('courses').doc('PRM392').set({
        id: 'PRM392',
        code: 'PRM392',
        name: 'Mobile Programming',
        credits: 3,
        status: 'published',
      });
    });

    const userDb = testEnv.authenticatedContext('user_123').firestore();
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
    });

    const staffDb = testEnv.authenticatedContext('staff_1').firestore();
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await context.firestore().collection('courses').doc('PRM392').set({
        code: 'PRM392',
        name: 'Mobile Programming',
        credits: 3,
        status: 'published',
      });
    });

    const staffDb = testEnv.authenticatedContext('staff_1').firestore();
    await assertFails(staffDb.collection('courses').doc('PRM392').delete());
  });

  // R-07B: courses - admin deletes a course -> Allowed
  it('R-07B: admin can hard delete a course', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('admin_1').set({
        uid: 'admin_1',
        role: 'admin',
      });
      await context.firestore().collection('courses').doc('PRM392').set({
        code: 'PRM392',
        name: 'Mobile Programming',
        credits: 3,
        status: 'published',
      });
    });

    const adminDb = testEnv.authenticatedContext('admin_1').firestore();
    await assertSucceeds(adminDb.collection('courses').doc('PRM392').delete());
  });

  // R-08: study_plans - user creates own plan with status == 'pending' -> Allowed
  it('R-08: user can create own study plan with status == "pending"', async () => {
    const userDb = testEnv.authenticatedContext('user_123').firestore();
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
    const userDb = testEnv.authenticatedContext('user_123').firestore();
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await context.firestore().collection('study_plans').doc('plan_1').set({
        userId: 'user_123',
        status: 'pending',
        semesterName: 'Fall 2026',
      });
    });

    const staffDb = testEnv.authenticatedContext('staff_1').firestore();
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user_123').set({
        uid: 'user_123',
        role: 'user',
      });
    });

    const userDb = testEnv.authenticatedContext('user_123').firestore();
    await assertFails(
      userDb.collection('announcements').doc('ann_1').set({
        title: 'Học bổng kỳ tới',
        status: 'published',
      })
    );
  });

  // R-12: announcements - staff creates new announcement with status == 'published' -> Allowed
  it('R-12: staff can create announcement with status == "published"', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
    });

    const staffDb = testEnv.authenticatedContext('staff_1').firestore();
    await assertSucceeds(
      staffDb.collection('announcements').doc('ann_1').set({
        title: 'Thông báo mở đăng ký môn chuyên ngành Fall 2026',
        status: 'published',
        createdAt: new Date(),
      })
    );
  });

  // Students collection verification
  it('Students: student can read & write own profile, staff/admin can read, other user denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('staff_1').set({
        uid: 'staff_1',
        role: 'staff',
      });
      await context.firestore().collection('users').doc('user_456').set({
        uid: 'user_456',
        role: 'user',
      });
    });

    const studentDb = testEnv.authenticatedContext('student_123').firestore();
    // Student creates own profile
    await assertSucceeds(
      studentDb.collection('students').doc('student_123').set({
        uid: 'student_123',
        fullName: 'Nguyen Van A',
        studentId: 'SE123456',
        currentGpa: 3.5,
      })
    );

    // Student creates completed_courses
    await assertSucceeds(
      studentDb.collection('students').doc('student_123').collection('completed_courses').doc('PRM392').set({
        code: 'PRM392',
        grade: 8.5,
        isPassed: true,
      })
    );

    // Staff can read student profile
    const staffDb = testEnv.authenticatedContext('staff_1').firestore();
    await assertSucceeds(
      staffDb.collection('students').doc('student_123').get()
    );
    await assertSucceeds(
      staffDb.collection('students').doc('student_123').collection('completed_courses').doc('PRM392').get()
    );

    // Another student cannot read
    const otherDb = testEnv.authenticatedContext('user_456').firestore();
    await assertFails(
      otherDb.collection('students').doc('student_123').get()
    );
    await assertFails(
      otherDb.collection('students').doc('student_123').collection('completed_courses').doc('PRM392').get()
    );
  });
});
