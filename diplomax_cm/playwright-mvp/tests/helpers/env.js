function toBool(value, defaultValue = false) {
  if (value === undefined || value === null || value === '') return defaultValue;
  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
}

function env(name, fallback = '') {
  const v = process.env[name];
  return v === undefined ? fallback : v;
}

module.exports = {
  toBool,
  env,
  cfg: {
    runLocal: toBool(process.env.RUN_LOCAL_API, false),
    runDeployed: toBool(process.env.RUN_DEPLOYED_API, true),
    strictAuth: toBool(process.env.RUN_STRICT_AUTH, false),
    studentUser: env('STUDENT_USERNAME', 'ICTU20223180'),
    studentPass: env('STUDENT_PASSWORD', ''),
    universityUser: env('UNIVERSITY_USERNAME', 'admin@ictuniversity.cm'),
    universityPass: env('UNIVERSITY_PASSWORD', ''),
    adminUser: env('ADMIN_USERNAME', 'admin@diplomax.cm'),
    adminPass: env('ADMIN_PASSWORD', 'DiplomaxAdmin2024!'),
    recruiterPassword: env('RECRUITER_PASSWORD', 'StrongPass123!'),
  },
};
