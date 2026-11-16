import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { CountdownTimer } from '../types'

const PANE = 'countdown'

const IDLE: CountdownTimer = {
  endAt: 0,
  left: 0,
  total: 0,
  label: '',
  isRunning: false,
  isDone: false,
  now: 0,
}

const timer = atom({ plugin: 'countdown', key: 'timer' } as const, IDLE, {
  shape: 'timer-1',
})

// 5-row glyphs, 3 columns wide ('#' = filled)
const BIG: Record<string, string[]> = {
  '0': ['###', '# #', '# #', '# #', '###'],
  '1': ['  #', '  #', '  #', '  #', '  #'],
  '2': ['###', '  #', '###', '#  ', '###'],
  '3': ['###', '  #', '###', '  #', '###'],
  '4': ['# #', '# #', '###', '  #', '  #'],
  '5': ['###', '#  ', '###', '  #', '###'],
  '6': ['###', '#  ', '###', '# #', '###'],
  '7': ['###', '  #', '  #', '  #', '  #'],
  '8': ['###', '# #', '###', '# #', '###'],
  '9': ['###', '# #', '###', '  #', '###'],
  ':': [' ', '#', ' ', '#', ' '],
}

function bigLines(text: string, glyph: string, wide: boolean): string[] {
  const rows = ['', '', '', '', '']
  const fill = wide ? glyph + glyph : glyph
  const gap = wide ? '  ' : ' '
  for (const ch of text) {
    const g = BIG[ch] ?? BIG['0'] ?? []
    for (let r = 0; r < 5; r++) {
      const row = (g[r] ?? '')
        .split('')
        .map(c => (c === '#' ? fill : gap))
        .join('')
      rows[r] = (rows[r] ?? '') + row + gap
    }
  }
  return rows
}

function fmt(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000))
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  const two = (n: number) => String(n).padStart(2, '0')
  return h > 0 ? `${h}:${two(m)}:${two(sec)}` : `${two(m)}:${two(sec)}`
}

// "25m", "90s", "1h30m", "5:00", "1:30:00", bare number = minutes
function parse(input: string): { ms: number; label: string } | undefined {
  const words = input.trim().split(/\s+/)
  const first = words[0] ?? ''
  const label = words.slice(1).join(' ')
  let ms = 0
  if (/^\d+(:\d+){1,2}$/.test(first)) {
    const p = first.split(':').map(Number)
    const [a = 0, b = 0, c = 0] = p
    ms = (p.length === 3 ? a * 3600 + b * 60 + c : a * 60 + b) * 1000
  } else if (/^(\d+h)?(\d+m)?(\d+s)?$/.test(first) && first !== '') {
    const m = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/.exec(first) ?? []
    ms = (Number(m[1] ?? 0) * 3600 + Number(m[2] ?? 0) * 60 + Number(m[3] ?? 0)) * 1000
  } else if (/^\d+$/.test(first)) {
    ms = Number(first) * 60000
  }
  return ms > 0 ? { ms, label } : undefined
}

export const register: Register = (on, options) => {
  const color = String(options?.color ?? '#cdd6f4')
  const doneColor = String(options?.doneColor ?? '#f38ba8')
  const wide = String(options?.scale ?? 'big') !== 'small'
  const glyph = String(options?.glyph || '█').slice(0, 1) || '█'

  let tick: { cancel: () => void } | undefined

  const stopTick = () => {
    tick?.cancel()
    tick = undefined
  }

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'countdown',
      description: 'Countdown: /countdown 25m [label] | pause | resume | stop',
    })
    return next(e)
  })

  on('command.run', { command: 'countdown' }, async ($, e) => {
    const arg = e.args.trim()
    const cmd = arg.toLowerCase()

    if (cmd === 'stop' || cmd === 'reset') {
      stopTick()
      await update($, timer, () => IDLE)
      $.ui.status(undefined)
      return { text: 'Countdown stopped.' }
    }

    if (cmd === 'pause') {
      const now = await $.clock.now()
      stopTick()
      await update($, timer, t =>
        t.isRunning ? { ...t, isRunning: false, left: Math.max(0, t.endAt - now), now } : t,
      )
      return { text: 'Countdown paused.' }
    }

    if (cmd === 'open' || cmd === '') {
      await $.ui.open({ id: PANE, title: 'Countdown' })
      if (cmd === '') {
        return { text: 'Usage: /countdown 25m [label] | 1h30m | 5:00 | pause | resume | stop' }
      }
      return { text: 'Countdown pane opened.' }
    }

    const start = async (ms: number, label: string, total: number) => {
      const now = await $.clock.now()
      stopTick()
      await update($, timer, () => ({
        endAt: now + ms,
        left: ms,
        total,
        label,
        isRunning: true,
        isDone: false,
        now,
      }))
      await $.ui.open({ id: PANE, title: 'Countdown' })
      tick = $.clock.every(1000, async () => {
        const t = await $.clock.now()
        const cur = await read($, timer)
        if (!cur.isRunning) return
        if (t >= cur.endAt) {
          stopTick()
          await update($, timer, c => ({ ...c, isRunning: false, isDone: true, left: 0, now: t }))
          $.ui.status(undefined)
          $.ui.toast(`Countdown finished${cur.label ? `: ${cur.label}` : ''}`)
          void $.ui.notify(cur.label || 'Time is up', { title: 'Countdown' }).catch(() => {})
          return
        }
        await update($, timer, c => ({ ...c, now: t }))
        $.ui.status(`${cur.label ? cur.label + ' ' : ''}${fmt(cur.endAt - t)}`)
      })
    }

    if (cmd === 'resume') {
      const cur = await read($, timer)
      if (cur.isRunning || cur.left <= 0) return { text: 'Nothing to resume.' }
      await start(cur.left, cur.label, cur.total)
      return { text: 'Countdown resumed.' }
    }

    const parsed = parse(arg)
    if (!parsed) {
      return { text: 'Could not read that time. Try: 25m, 90s, 1h30m, 5:00' }
    }
    await start(parsed.ms, parsed.label, parsed.ms)
    return { text: `Countdown started: ${fmt(parsed.ms)}${parsed.label ? ` (${parsed.label})` : ''}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const t = await read($, timer)
    const now = t.now || 0
    const remaining = t.isRunning ? Math.max(0, t.endAt - now) : t.left
    const idle = !t.isRunning && !t.isDone && t.left === 0
    const text = fmt(idle ? 0 : remaining)
    const lines = bigLines(text, glyph, wide)
    const shade = t.isDone ? doneColor : color
    const pct = t.total > 0 ? Math.round(((t.total - remaining) / t.total) * 100) : 0
    const cols = Math.max(10, (e.props?.bodyColumns as number | undefined) ?? 40)
    const barW = Math.min(cols - 2, 40)
    const filled = Math.round((pct / 100) * barW)

    return (
      <Box flexDirection="column" alignItems="center" justifyContent="center" paddingY={1}>
        {t.label ? <Text bold>{t.label}</Text> : null}
        {lines.map(l => (
          <Text color={shade}>{l}</Text>
        ))}
        {t.total > 0 ? (
          <Text color={shade}>
            {'█'.repeat(filled)}
            <Text dimColor>{'░'.repeat(barW - filled)}</Text> {pct}%
          </Text>
        ) : null}
        <Text dimColor>
          {idle
            ? '/countdown 25m [label]'
            : t.isDone
              ? 'finished  ·  /countdown stop'
              : t.isRunning
                ? 'running  ·  /countdown pause | stop'
                : 'paused  ·  /countdown resume | stop'}
        </Text>
      </Box>
    )
  })
}
