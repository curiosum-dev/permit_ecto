defmodule Mixin do
  defmacro __using__(_) do
    quote do
      defmacro macro(arg) do
        quote do
          "macro/1, arg: #{unquote(arg)}"
        end
      end
    end
  end
end

defmodule TransitiveMixin do
  defmacro __using__(_) do
    quote do

      use Mixin

      import TransitiveMixin
    end
  end
end

defmodule Mod do
  use Mixin

  def foo(arg) do
    macro(arg)
  end
end
