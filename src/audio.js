/* ============ AUDIO — WebAudio synth, 0 byte asset ============ */
const AU={ctx:null,on:true,vol:0.28};
function ac(){ if(!AU.ctx){ try{ AU.ctx=new (window.AudioContext||window.webkitAudioContext)(); }catch(e){ AU.on=false; } } return AU.ctx; }
function env(g,t,a,d,pk){ g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(pk,t+a); g.gain.exponentialRampToValueAtTime(0.0001,t+a+d); }
function tone(f,dur,type,pk,slide,delay){
  if(!AU.on) return; const c=ac(); if(!c) return;
  const t=c.currentTime+(delay||0), o=c.createOscillator(), g=c.createGain();
  o.type=type||'square'; o.frequency.setValueAtTime(f,t);
  if(slide) o.frequency.exponentialRampToValueAtTime(Math.max(30,slide),t+dur);
  env(g,t,0.004,dur,(pk||0.3)*AU.vol); o.connect(g); g.connect(c.destination); o.start(t); o.stop(t+dur+0.05);
}
let NB=null;
function noise(dur,pk,filt,delay,q){
  if(!AU.on) return; const c=ac(); if(!c) return;
  if(!NB){ NB=c.createBuffer(1,c.sampleRate*0.5,c.sampleRate); const d=NB.getChannelData(0);
    for(let i=0;i<d.length;i++) d[i]=Math.random()*2-1; }
  const t=c.currentTime+(delay||0), s=c.createBufferSource(), g=c.createGain(), f=c.createBiquadFilter();
  s.buffer=NB; f.type='bandpass'; f.frequency.value=filt||900; f.Q.value=q||1;
  env(g,t,0.003,dur,(pk||0.25)*AU.vol); s.connect(f); f.connect(g); g.connect(c.destination); s.start(t); s.stop(t+dur+0.05);
}
const SFX={
  ui:()=>tone(680,0.05,'square',0.16),
  hover:()=>tone(1200,0.025,'sine',0.07),
  tray:()=>noise(0.14,0.16,420,0,0.8),
  tumble:(i)=>noise(0.035,0.11,1500+i*120,0,2),
  land:(i,rar)=>{ const base=[392,440,494,523,587][i%5];
    tone(base,0.09,'square',0.2); noise(0.05,0.14,1100,0,1.5);
    if(rar>=1) tone(base*2,0.13,'triangle',0.14,null,0.04);
    if(rar>=3) tone(base*3,0.22,'sine',0.16,null,0.08); },
  heavy:()=>{ tone(70,0.24,'sawtooth',0.34,40); noise(0.14,0.24,240,0,0.7); },
  hit:(m)=>{ noise(0.09,0.24+Math.min(0.2,m/160),260+m*3,0,0.7); tone(150-Math.min(70,m),0.11,'square',0.2,60); },
  crit:()=>{ noise(0.16,0.4,3000,0,3); tone(1180,0.13,'square',0.3,420); tone(300,0.26,'sawtooth',0.28,90,0.03); },
  heal:()=>{ tone(523,0.16,'sine',0.24,784); tone(784,0.2,'sine',0.16,null,0.06); },
  shield:()=>{ tone(880,0.13,'triangle',0.22,1320); noise(0.07,0.1,2600,0,3); },
  mana:()=>{ tone(1046,0.16,'sine',0.2); tone(1568,0.2,'sine',0.13,null,0.05); },
  poison:()=>{ tone(190,0.16,'sine',0.22,110); noise(0.09,0.1,520,0,2); },
  burn:()=>noise(0.22,0.2,1700,0,0.6),
  die:()=>{ tone(220,0.36,'sawtooth',0.3,60); noise(0.24,0.2,340,0,0.6); },
  kill:()=>{ noise(0.2,0.28,700,0,0.5); tone(120,0.3,'square',0.24,50,0.02); },
  reroll:()=>{ noise(0.18,0.18,900,0,1); tone(500,0.1,'square',0.14,760); },
  legend:()=>{ [523,659,784].forEach((f,i)=>tone(f,0.5,'triangle',0.2,null,i*0.06)); noise(0.4,0.14,3400,0,2); },
  levelup:()=>{ [392,494,587,784].forEach((f,i)=>tone(f,0.16,'square',0.22,null,i*0.05)); noise(0.15,0.12,2200,0,1); },
  passClaim:()=>{ [440,554,659,880,1109].forEach((f,i)=>tone(f,0.6,'triangle',0.2,null,i*0.045)); noise(0.5,0.15,3800,0,2); },
  mythic:()=>{ [392,523,659,784,1046].forEach((f,i)=>tone(f,0.85,'triangle',0.22,null,i*0.05));
    tone(90,0.9,'sawtooth',0.26,45); noise(0.7,0.16,4200,0.05,2); },
  warn:()=>{ tone(320,0.18,'square',0.26); tone(320,0.18,'square',0.26,null,0.24); },
  boss:()=>{ tone(70,1.0,'sawtooth',0.34,38); [147,175,220].forEach((f,i)=>tone(f,0.7,'square',0.16,null,0.1+i*0.07)); },
  win:()=>[523,659,784,1046,1318].forEach((f,i)=>tone(f,0.55,'triangle',0.24,null,i*0.1)),
  lose:()=>[440,392,330,247].forEach((f,i)=>tone(f,0.55,'sawtooth',0.24,null,i*0.16)),
  coin:()=>{ tone(1318,0.09,'square',0.2); tone(1760,0.13,'square',0.16,null,0.05); },
  open:()=>{ noise(0.24,0.16,1300,0,1); tone(400,0.24,'triangle',0.16,900); },
};
