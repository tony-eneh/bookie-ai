/**
 * Minimal, self-contained page linked from the password reset email. It is
 * served by the API itself (same origin as POST /auth/reset-password), so it
 * needs no CORS configuration. The token stays in the page URL; the script
 * posts it with the new password as JSON.
 */
export const RESET_PASSWORD_PAGE = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<meta name="referrer" content="no-referrer">
<title>Reset your BookieAI password</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: grid; place-items: center;
    background: #12131f; color: #f4f5fb; padding: 24px;
    font: 16px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; }
  main { width: 100%; max-width: 380px; background: #1a1b2e;
    border: 1px solid rgba(255,255,255,.08); border-radius: 20px; padding: 32px; }
  h1 { font-size: 22px; margin: 0 0 6px; }
  p { color: #a3a4b8; margin: 0 0 22px; }
  label { display: block; font-size: 14px; color: #a3a4b8; margin: 14px 0 6px; }
  input { width: 100%; padding: 13px 14px; border-radius: 12px; font: inherit;
    border: 1px solid rgba(255,255,255,.14); background: #12131f; color: inherit; }
  input:focus { outline: 2px solid #00d09c; outline-offset: 1px; }
  button { width: 100%; margin-top: 22px; padding: 14px; border: 0; border-radius: 999px;
    font: 600 16px system-ui, sans-serif; color: #06231c; cursor: pointer;
    background: linear-gradient(120deg, #00d09c, #00b8d4); }
  button:disabled { opacity: .6; cursor: default; }
  .msg { margin-top: 16px; font-size: 14px; min-height: 1.5em; }
  .err { color: #ff8a8a; } .ok { color: #00e4ab; }
  .brand { font-weight: 800; letter-spacing: -.02em; margin-bottom: 20px; }
  .brand b { color: #00d09c; }
</style>
</head>
<body>
<main>
  <div class="brand">Bookie<b>AI</b></div>
  <h1>Choose a new password</h1>
  <p>Use at least 8 characters. You'll be signed out on your other devices.</p>
  <form id="f" novalidate>
    <label for="p1">New password</label>
    <input id="p1" type="password" autocomplete="new-password" minlength="8" required>
    <label for="p2">Confirm password</label>
    <input id="p2" type="password" autocomplete="new-password" minlength="8" required>
    <button id="b" type="submit">Update password</button>
    <div id="m" class="msg" role="status" aria-live="polite"></div>
  </form>
</main>
<script>
(function () {
  var token = new URLSearchParams(location.search).get('token') || '';
  var form = document.getElementById('f'), msg = document.getElementById('m'),
      btn = document.getElementById('b');
  function show(text, ok) { msg.textContent = text; msg.className = 'msg ' + (ok ? 'ok' : 'err'); }
  if (!token) { show('This link is missing its reset token. Request a new one from the app.'); btn.disabled = true; }
  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var p1 = document.getElementById('p1').value, p2 = document.getElementById('p2').value;
    if (p1.length < 8) return show('Use at least 8 characters.');
    if (p1 !== p2) return show("The passwords don't match.");
    btn.disabled = true; show('');
    fetch(location.pathname, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: token, newPassword: p1 })
    }).then(function (r) {
      return r.json().catch(function () { return {}; }).then(function (body) {
        if (r.ok) {
          form.innerHTML = '';
          show('Password updated. Open the BookieAI app and sign in with your new password.', true);
          form.appendChild(msg);
        } else {
          var m = body && body.message;
          show(Array.isArray(m) ? m.join(' ') : (m || 'Something went wrong. Please try again.'));
          btn.disabled = false;
        }
      });
    }).catch(function () { show('Network error. Please try again.'); btn.disabled = false; });
  });
})();
</script>
</body>
</html>
`;
