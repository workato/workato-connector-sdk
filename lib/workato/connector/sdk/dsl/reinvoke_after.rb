# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module ReinvokeAfter
          extend T::Sig

          sig do
            params(
              continue: T::Hash[T.untyped, T.untyped],
              temp_output: T.nilable(T::Hash[T.untyped, T.untyped])
            ).void
          end
          def checkpoint!(continue:, temp_output: nil)
            # no-op
          end

          sig do
            params(
              seconds: T.any(Integer, Float),
              continue: T::Hash[T.untyped, T.untyped],
              temp_output: T.nilable(T::Hash[T.untyped, T.untyped])
            ).void
          end
          def reinvoke_after(seconds:, continue:, temp_output: nil) # rubocop:disable Lint/UnusedMethodArgument
            Kernel.throw REINVOKE_AFTER_SIGNAL, ReinvokeParams.new(
              seconds: seconds,
              continue: continue
            )
          end

          private

          MAX_REINVOKES = 5
          private_constant :MAX_REINVOKES

          REINVOKE_AFTER_SIGNAL = :reinvoke_after
          private_constant :REINVOKE_AFTER_SIGNAL

          class ReinvokeParams < T::Struct
            prop :seconds, T.any(Float, Integer)
            prop :continue, T::Hash[T.untyped, T.untyped]
          end
          private_constant :ReinvokeParams

          sig { params(continue: T::Hash[T.any(Symbol, String), T.untyped], _blk: Proc).returns(T.untyped) }
          def loop_reinvoke_after(continue, &_blk)
            reinvokes_remaining = T.let(reinvoke_limit, Integer)

            Kernel.loop do
              reinvoke_after = Kernel.catch(REINVOKE_AFTER_SIGNAL) do
                return yield(continue)
              end

              if reinvokes_remaining.zero?
                Kernel.raise "Max number of reinvokes on SDK Gem reached. Current limit is #{reinvoke_limit}"
              end

              reinvokes_remaining -= 1

              reinvoke_after = T.cast(reinvoke_after, ReinvokeParams)
              reinvoke_sleep(reinvoke_after.seconds)
              continue = reinvoke_after.continue
            end
          end

          sig { params(seconds: T.any(Float, Integer)).void }
          def reinvoke_sleep(seconds)
            Kernel.sleep((ENV['WAIT_REINVOKE_AFTER'].presence || seconds).to_f)
          end

          sig { returns(Integer) }
          def reinvoke_limit
            @reinvoke_limit ||= T.let((ENV['MAX_REINVOKES'].presence || MAX_REINVOKES).to_i, T.nilable(Integer))
          end
        end
      end
    end
  end
end
