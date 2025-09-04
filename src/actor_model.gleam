import gleam/io
import gleam/int
import gleam/otp/actor
import gleam/erlang/process

// State
type State { State(count: Int) }

// Messages
type Msg {
  Increment
  Get(reply_to: process.Subject(Int))
  Stop
}

// Handler: (state, msg) -> Next(state, msg)
fn handle(state: State, msg: Msg) -> actor.Next(State, Msg) {
  case msg {
    Increment -> {
      let State(count) = state
      actor.continue(State(count + 1))
    }

    Get(reply_to) -> {
      let State(count) = state
      process.send(reply_to, count)
      actor.continue(state)
    }

    Stop -> actor.stop()
  }
}

pub fn main() {
  let builder = actor.new(State(0)) |> actor.on_message(handle)
  let assert Ok(started) = actor.start(builder)
  let subject = started.data

  actor.send(subject, Increment)
  actor.send(subject, Increment)

  // call(subject, waiting: timeout_ms, sending: constructor-or-fn)
  let total = actor.call(subject, waiting: 1000, sending: Get)
  io.println("Final count: " <> int.to_string(total))

  actor.send(subject, Stop)
}
