defmodule Permit.Permissions.PatternCompilerTest do
  use ExUnit.Case, async: true

  # Helper to compare regex structs by their source and options
  defp assert_regex_equal(actual, expected) do
    assert actual.source == expected.source
    assert actual.opts == expected.opts
  end

  describe "to_regex/2" do
    import Permit.Operators.Ilike.PatternCompiler,
      only: [to_regex: 2]

    test "ignore case when needed" do
      assert_regex_equal(to_regex("abc[dupa]", ignore_case: true), ~r/^abc\[dupa\]$/i)
      assert_regex_equal(to_regex("abc[du-pa]", ignore_case: true), ~r/^abc\[du\-pa\]$/i)
      assert_regex_equal(to_regex("^ab$c(dupa)", ignore_case: false), ~r/^\^ab\$c\(dupa\)$/)
      assert_regex_equal(to_regex(".*", ignore_case: true), ~r/^\.\*$/i)
    end

    test "doubled escape character is replaced" do
      assert_regex_equal(
        to_regex("ab!!c[dupa]", ignore_case: true, escape: "!"),
        ~r/^ab!c\[dupa\]$/i
      )

      assert_regex_equal(
        to_regex("!!abc[du-pa]!!", ignore_case: false, escape: "!"),
        ~r/^!abc\[du\-pa\]!$/
      )

      assert_regex_equal(to_regex("^a!!!!b$c(dupa)", escape: "!"), ~r/^\^a!!b\$c\(dupa\)$/)
      assert_regex_equal(to_regex("!!.!!*!!", escape: "!"), ~r/^!\.!\*!$/)
    end

    test "escape character works with %" do
      assert_regex_equal(
        to_regex("CHUJCHUJa!!p!%a", ignore_case: true, escape: "!"),
        ~r/^CHUJCHUJa!p%a$/i
      )

      assert_regex_equal(
        to_regex("!!!%%abc[du-pa]!!", ignore_case: false, escape: "!"),
        ~r/^!%.*abc\[du\-pa\]!$/
      )

      assert_regex_equal(to_regex("^a!!!%!!b$c(dupa)!%", escape: "!"), ~r/^\^a!%!b\$c\(dupa\)%$/)
      assert_regex_equal(to_regex("%!!.%!%!!*!!%", escape: "!"), ~r/^.*!\..*%!\*!.*$/)
    end

    test "escape character works with _" do
      assert_regex_equal(
        to_regex("__!_CHUJCHUJa!!p!%a", ignore_case: true, escape: "!"),
        ~r/^.._CHUJCHUJa!p%a$/i
      )

      assert_regex_equal(
        to_regex("!!!%!__%abc[du-pa]!!", ignore_case: false, escape: "!"),
        ~r/^!%_..*abc\[du\-pa\]!$/
      )

      assert_regex_equal(to_regex("^!!_a!!!%!!b$!%!_", escape: "!"), ~r/^\^!.a!%!b\$%_$/)
      assert_regex_equal(to_regex("%!%!_%_.%!%!!*!!%", escape: "!"), ~r/^.*%_.*.\..*%!\*!.*$/)
    end
  end

  describe "to_regex/1" do
    import Permit.Operators.Ilike.PatternCompiler,
      only: [to_regex: 1]

    test "simple conversions" do
      assert_regex_equal(to_regex("abc"), ~r/^abc$/)
      assert_regex_equal(to_regex("123 ab c"), ~r/^123\ ab\ c$/)
    end

    test "escape special regex characters" do
      assert_regex_equal(to_regex("abc[dupa]"), ~r/^abc\[dupa\]$/)
      assert_regex_equal(to_regex("abc[du-pa]"), ~r/^abc\[du\-pa\]$/)
      assert_regex_equal(to_regex("^ab$c(dupa)"), ~r/^\^ab\$c\(dupa\)$/)
      assert_regex_equal(to_regex(".*"), ~r/^\.\*$/)
    end

    test "replace % with .*" do
      assert_regex_equal(to_regex("abc[du%pa]"), ~r/^abc\[du.*pa\]$/)
      assert_regex_equal(to_regex("a%bc[du-pa%]"), ~r/^a.*bc\[du\-pa.*\]$/)
      assert_regex_equal(to_regex("%^ab$c(dupa)%"), ~r/^.*\^ab\$c\(dupa\).*$/)
      assert_regex_equal(to_regex(".*%"), ~r/^\.\*.*$/)
    end

    test "replace _ with ." do
      assert_regex_equal(to_regex("a_bc[du%pa]"), ~r/^a.bc\[du.*pa\]$/)
      assert_regex_equal(to_regex("_a%bc[du-_pa%]"), ~r/^.a.*bc\[du\-.pa.*\]$/)
      assert_regex_equal(to_regex("%^a__b$c(dupa)__%"), ~r/^.*\^a..b\$c\(dupa\)...*$/)
      assert_regex_equal(to_regex("___.*%"), ~r/^...\.\*.*$/)
    end
  end
end
