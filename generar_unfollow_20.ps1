$base = 'C:\Users\Tomas\Downloads\instagram-ecddysis-2026-10-02-IizN6sfd\connections\followers_and_following'
$followersJson = Get-Content -Raw -LiteralPath (Join-Path $base 'followers_1.json') | ConvertFrom-Json
$followingJson = Get-Content -Raw -LiteralPath (Join-Path $base 'following.json') | ConvertFrom-Json
$followers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$followersJson | ForEach-Object { $_.string_list_data | ForEach-Object { if ($_.value) { [void]$followers.Add($_.value) } } }
$accounts = $followingJson.relationships_following | ForEach-Object { $_.title } | Sort-Object -Unique | Where-Object { -not $followers.Contains($_) -and $_ -notlike '__deleted__*' }
$accountsJson = $accounts | ConvertTo-Json -Compress
$template = @'
const accounts = __ACCOUNTS__;
const batchSize = 25;
const key = 'igUnfollowOct02Done';
const pause = ms => new Promise(r => setTimeout(r, ms));
const visible = e => e && !!(e.offsetWidth || e.offsetHeight || e.getClientRects().length);
const content = e => (e?.innerText || e?.textContent || '').trim();
const buttons = () => [...document.querySelectorAll('button')].filter(visible);
const exactButton = (...labels) => buttons().find(e => labels.some(label => content(e).toLowerCase() === label.toLowerCase()));
const targets = new Set(accounts);
const completed = new Set(JSON.parse(localStorage.getItem(key) || '[]'));
function userNearButton(button) {
  for (let node = button.parentElement; node && node !== document.body; node = node.parentElement) {
    const lines = content(node).split('\n').map(x => x.trim()).filter(Boolean);
    if (lines.length > 6) continue;
    const matches = lines.filter(line => targets.has(line));
    if (matches.length === 1) return matches[0];
  }
  return null;
}
function scrollDialog() {
  const dialogs = [...document.querySelectorAll('[role="dialog"]')].filter(visible);
  const dialog = dialogs.find(e => /seguidores|siguiendo|followers|following/i.test(content(e))) || dialogs[0];
  if (!dialog) return false;
  const target = [...dialog.querySelectorAll('*')].filter(e => e.scrollHeight > e.clientHeight + 80).sort((a,b) => b.clientHeight-a.clientHeight)[0];
  if (!target) return false;
  const distance = Math.max(350, target.clientHeight * .8);
  const atBottom = target.scrollTop >= target.scrollHeight - target.clientHeight - 5;
  target.scrollBy({top: atBottom ? -distance : distance, behavior:'smooth'}); return true;
}
let done = 0, emptyScans = 0;
for (let scans = 0; scans < 150 && done < batchSize; scans++) {
  const candidate = buttons().find(button => {
    const user = userNearButton(button);
    return /^(siguiendo|following)$/i.test(content(button)) && user && !completed.has(user);
  });
  if (!candidate) {
    emptyScans++;
    if (emptyScans >= 20 || !scrollDialog()) break;
    await pause(700); continue;
  }
  emptyScans = 0;
  const user = userNearButton(candidate);
  candidate.click(); await pause(700);
  const confirm = exactButton('Dejar de seguir', 'Unfollow');
  if (confirm) confirm.click();
  else if (!exactButton('Seguir', 'Follow')) { console.warn('No aparecio confirmacion para @'+user+'. Detenido por seguridad.'); break; }
  await pause(900); completed.add(user); localStorage.setItem(key, JSON.stringify([...completed])); done++; console.log('Hecho @'+user);
}
console.log('Procesadas: '+done+'. Avance: '+completed.size+'/'+accounts.length);
'@
$template.Replace('__ACCOUNTS__', $accountsJson) | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'unfollow_67_consola.js') -Encoding utf8
Write-Host "Generado: unfollow_67_consola.js ($($accounts.Count) cuentas)"
