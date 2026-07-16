// Vercel Serverless Function — /api/lead
// Recibe el formulario de contacto y lo reenvía a Google Apps Script DESDE EL
// SERVIDOR. Así el navegador del visitante solo habla con trm-spain.com (mismo
// dominio), y ningún bloqueador de anuncios/privacidad puede bloquear el envío.
//
// Si algún día vuelves a publicar el Apps Script y cambia la URL /exec,
// actualízala aquí (o define la variable de entorno APPS_SCRIPT_URL en Vercel).

const APPS_SCRIPT_URL =
  process.env.APPS_SCRIPT_URL ||
  'https://script.google.com/macros/s/AKfycbyXMTkT8xSDaAOxJyzUIUN-P8mWlyOt6cjBWOw8a_y-KpSQjMER5NAzZP5jLwZ-XTLO/exec';

const FIELDS = ['nombre', 'email', 'telefono', 'mensaje', 'origen'];

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  try {
    // Vercel parsea automáticamente JSON y x-www-form-urlencoded en req.body
    const b = (req.body && typeof req.body === 'object') ? req.body : {};

    // Honeypot anti-spam: si el campo trampa viene relleno, fingimos éxito y descartamos.
    if (b._gotcha) return res.status(200).json({ ok: true });

    // Validación mínima
    const email = String(b.email || '').trim();
    const nombre = String(b.nombre || '').trim();
    if (!nombre || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return res.status(400).json({ ok: false, error: 'Datos incompletos' });
    }

    const params = new URLSearchParams();
    for (const k of FIELDS) {
      params.append(k, String(b[k] == null ? '' : b[k]).slice(0, 3000));
    }

    const r = await fetch(APPS_SCRIPT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params.toString(),
    });

    let ok = r.ok;
    const text = await r.text();
    try { ok = JSON.parse(text).ok === true; } catch (_) { /* respuesta no-JSON: nos quedamos con r.ok */ }

    return res.status(ok ? 200 : 502).json({ ok });
  } catch (e) {
    return res.status(500).json({ ok: false, error: String(e && e.message || e) });
  }
}
