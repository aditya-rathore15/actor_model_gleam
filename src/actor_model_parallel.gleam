import gleam/io
import gleam/int
import gleam/otp/actor
import gleam/erlang/process

// * Important Command for CPU and Real time *
// /usr/bin/time -l gleam run -m actor_model_parallel

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
  // Make two actors
  let builder = actor.new(State(0)) |> actor.on_message(handle)
  let assert Ok(started1) = actor.start(builder)
  let assert Ok(started2) = actor.start(builder)

  let subject1 = started1.data
  let subject2 = started2.data

  // Send messages to both actors (in parallel)
  actor.send(subject1, Increment)
  actor.send(subject2, Increment)

  // Ask each actor for its result
  let total1 = actor.call(subject1, waiting: 1000, sending: Get)
  let total2 = actor.call(subject2, waiting: 1000, sending: Get)

  io.println("Actor 1: " <> int.to_string(total1))
  io.println("Actor 2: " <> int.to_string(total2))

  

  // Stop both
  actor.send(subject1, Stop)
  actor.send(subject2, Stop)
}
