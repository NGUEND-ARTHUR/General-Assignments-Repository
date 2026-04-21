const { expect } = require('@playwright/test');

function uniqueEmail(prefix = 'user') {
  return `${prefix}+${Date.now()}_${Math.floor(Math.random() * 10000)}@ictuniversity.edu.cm`;
}

async function login(request, email, password) {
  const response = await request.post('/auth/login', {
    data: { email, password },
  });
  expect(response.ok()).toBeTruthy();
  const payload = await response.json();
  return {
    token: payload.access_token,
    user: payload.user,
  };
}

async function register(request, data) {
  const response = await request.post('/auth/register', {
    data,
  });
  expect(response.ok()).toBeTruthy();
  const payload = await response.json();
  return {
    token: payload.access_token,
    user: payload.user,
  };
}

async function authGet(request, url, token) {
  return request.get(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
}

async function authPost(request, url, token, data) {
  const resp = await request.post(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    data,
  });
  return resp;
}

async function authPut(request, url, token, data) {
  return request.put(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    data,
  });
}

async function authDelete(request, url, token, data) {
  return request.delete(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    data,
  });
}

module.exports = {
  uniqueEmail,
  login,
  register,
  authGet,
  authPost,
  authPut,
  authDelete,
};
