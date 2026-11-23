import base64, io, re
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
p = root / 'web' / 'loading.html'
s = p.read_text()
img = Image.open(root / 'assets/reclaim/ui/loading_art.png').convert('RGB')
img = img.resize((1280, int(1280 * img.height / img.width)), Image.LANCZOS)
buf = io.BytesIO(); img.save(buf, 'JPEG', quality=80, optimize=True)
b64 = base64.b64encode(buf.getvalue()).decode()
print('art bytes', len(buf.getvalue()))

style = '''  <style>
    :root { color-scheme: dark; font-family: system-ui, -apple-system, "Noto Sans KR", sans-serif; background: #0b0609; color: #f2edf0; }
    * { box-sizing: border-box; }
    html, body { width: 100%; height: 100%; margin: 0; overflow: hidden; background: #0b0609; }
    #canvas { display: block; width: 100%; height: 100%; outline: none; }
    #loading { position: fixed; inset: 0; z-index: 4; background: #0b0609 url("data:image/jpeg;base64,__ART__") center / cover no-repeat; }
    #loading[hidden], [hidden] { display: none !important; }
    /* approved loading art: logo is part of the illustration (top-left); real UI sits bottom-right */
    .panel { position: absolute; right: 3.6%; bottom: 6%; width: min(560px, 40vw); min-width: 280px; padding: 14px 18px 16px; background: linear-gradient(90deg, rgba(10,4,7,.0), rgba(10,4,7,.86) 18%); text-align: left; }
    h1 { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); margin: 0; }
    #loading-status { margin: 0 0 10px; color: #fff; font-size: clamp(16px, 1.9vw, 26px); font-weight: 700; text-shadow: 0 2px 3px #000; }
    .row { display: flex; align-items: center; gap: 14px; }
    progress { flex: 1; height: clamp(14px, 1.8vw, 24px); border: 2px solid #e8333a; border-radius: 3px; overflow: hidden; appearance: none; background: #2a0c10; accent-color: #e8333a; }
    progress::-webkit-progress-bar { background: #2a0c10; }
    progress::-webkit-progress-value { background: linear-gradient(#ff8a8a, #e8333a 45%, #b3141c); }
    progress::-moz-progress-bar { background: #e8333a; }
    #loading-pct { min-width: 3.4em; color: #fff; font-size: clamp(20px, 2.6vw, 38px); font-weight: 800; text-align: right; text-shadow: 0 2px 3px #000; }
    #loading-notice { max-width: 420px; margin: 10px 0 0; color: #e7d8de; line-height: 1.5; font-size: 14px; }
    #loading-retry { margin-top: 10px; min-height: 44px; padding: 0 22px; border: 2px solid #e8333a; border-radius: 3px; background: #3b0b10; color: #fff; font: inherit; cursor: pointer; }
    #loading-retry:focus-visible { outline: 3px solid #fff; outline-offset: 3px; }
    @media (prefers-reduced-motion: no-preference) { progress:indeterminate { animation: breathe 1.2s ease-in-out infinite alternate; } @keyframes breathe { from { opacity: .55; } to { opacity: 1; } } }
  </style>'''.replace('__ART__', b64)
s = re.sub(r'  <style>.*?</style>', lambda m: style, s, count=1, flags=re.S)
section = '''  <section id="loading" role="status" aria-live="polite">
    <h1 id="game-title">OPERATION: RECLAIM — 수도 탈환 작전</h1>
    <div class="panel">
      <p id="loading-status">작전 준비 중...</p>
      <div class="row"><progress id="loading-progress" aria-label="게임 다운로드 진행률"></progress><span id="loading-pct">0%</span></div>
      <p id="loading-notice" hidden></p>
      <button id="loading-retry" type="button" hidden>다시 시도</button>
    </div>
    <noscript>게임을 실행하려면 JavaScript가 필요합니다.</noscript>
  </section>'''
s = re.sub(r'  <section id="loading".*?</section>', lambda m: section, s, count=1, flags=re.S)
s = s.replace("const retry = document.getElementById('loading-retry');",
              "const retry = document.getElementById('loading-retry');\n      const pct = document.getElementById('loading-pct');\n      // keyboard focus for WASD: clicking anywhere focuses the game canvas\n      canvas.addEventListener('pointerdown', () => canvas.focus());")
s = s.replace("status.textContent = '작전 지역을 준비하고 있습니다…';\n        return;",
              "status.textContent = '작전 준비 중...';\n        return;")
s = s.replace("status.textContent = current >= total ? '게임을 시작합니다…' : `불러오는 중 ${Math.floor(current / total * 100)}%`;",
              "pct.textContent = `${Math.floor(Math.min(current, total) / total * 100)}%`;\n        status.textContent = current >= total ? '작전 개시 준비 완료' : '작전 준비 중... 데이터 수신';")
s = s.replace("progress.hidden = true;\n        notice.hidden = true;", "progress.hidden = true;\n        pct.hidden = true;\n        notice.hidden = true;")
s = s.replace("if (config['focusCanvas']) canvas.focus();", "canvas.focus();")
assert 'loading-pct' in s and 'pointerdown' in s and 'manus-game-loading-screen' in s
p.write_text(s)
print('loading.html updated', len(s))
