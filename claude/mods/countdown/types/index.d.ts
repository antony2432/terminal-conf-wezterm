export type CountdownTimer = {
  /** epoch ms when it hits zero; 0 when not running */
  endAt: number
  /** remaining ms while paused or idle */
  left: number
  total: number
  label: string
  isRunning: boolean
  isDone: boolean
  /** last tick, epoch ms, to redraw */
  now: number
}

declare module 'claude-code' {
  interface PluginState {
    countdown: { timer: Shaped<CountdownTimer> }
  }
}
