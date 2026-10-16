const accounts = ["_.shinjitsu","1_baiper","albert_andres_vargas","astystories","avellismo","babyjey619","bananirou","blast.fury","bunblge._","bvsureta","bydiianarz","carmengatitos","chilegramvideos","cobratate","darhi.donyaris","ecclipccee","elkrust","estamos_pato","felipe.b.1","flex_cl","glam.americano","haotlskdl","heeeeeeerz","helidifkfkfk","henriquez_mcua","ibenjagarrido","ihbrahii","ikarakim","ingenieriaquimica","itsclau_0002","janitopx","jfkdldkfjd82929._","julionoestito","juniorplayboy69","kallemarket.cl","kitibellakazf","la_flare_777","latazosdiegonotdead","livesnocturnos","magic_sneakers.cl","mango_uwu_dulce","maniacoschile","matiasperear","miseriaboi","neroprojectcl","ninho_indigo","nohablamosconpolicia","parkour.stunt_","por_que_no_naci_perro","potitooooosssss","rondilda","sadikthegoat","shittpostiing","shonci","somethingabout_thesunshine","suruyito.shitposting","susan_brown__804","sxckit_","talesfromthestreets2","tendencia.chile","the.incredible.sully","theclappsycho","valeriaavila9126","valorclipss","vikceldotcom","vworldcl","welintoncastillo24"];
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
