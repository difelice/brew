# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      class Text < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          if !find_node_method_by_name(body_node, :plist_options) &&
             find_method_def(body_node, :plist)
            problem "Please set plist_options when using a formula-defined plist."
          end

          if (depends_on?("openssl") || depends_on?("openssl@1.1")) && depends_on?("libressl")
            problem "Formulae should not depend on both OpenSSL and LibreSSL (even optionally)."
          end

          if formula_tap == "homebrew-core" && (depends_on?("veclibfort") || depends_on?("lapack"))
            problem "Formulae in homebrew/core should use OpenBLAS as the default serial linear algebra library."
          end

          if method_called_ever?(body_node, :virtualenv_create) ||
             method_called_ever?(body_node, :virtualenv_install_with_resources)
            find_method_with_args(body_node, :resource, "setuptools") do
              problem "Formulae using virtualenvs do not need a `setuptools` resource."
            end
          end

          unless method_called_ever?(body_node, :go_resource)
            # processed_source.ast is passed instead of body_node because `require` would be outside body_node
            find_method_with_args(processed_source.ast, :require, "language/go") do
              problem "require \"language/go\" is unnecessary unless using `go_resource`s"
            end
          end

          find_instance_method_call(body_node, "Formula", :factory) do
            problem "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\""
          end

          find_every_method_call_by_name(body_node, :xcodebuild).each do |m|
            next if parameters_passed?(m, /SYMROOT=/)

            problem 'xcodebuild should be passed an explicit "SYMROOT"'
          end

          find_method_with_args(body_node, :system, "xcodebuild") do
            problem %q(use "xcodebuild *args" instead of "system 'xcodebuild', *args")
          end

          find_method_with_args(body_node, :system, "go", "get") do
            problem "Do not use `go get`. Please ask upstream to implement Go vendoring"
          end

          find_method_with_args(body_node, :system, "dep", "ensure") do |d|
            next if parameters_passed?(d, /vendor-only/)

            problem "use \"dep\", \"ensure\", \"-vendor-only\""
          end

          find_method_with_args(body_node, :system, "cargo", "build") do
            problem "use \"cargo\", \"install\", \"--root\", prefix, \"--path\", \".\""
          end

          find_method_with_args(body_node, :go_resource) do
            problem "`go_resource`s are deprecated. Please ask upstream to implement Go vendoring"
          end
        end
      end
    end

    # Keep this (empty) module and class around in case we need it later to
    # avoid deleting all the FormulaAuditStrict referencing logic.
    module FormulaAuditStrict
      class Text < FormulaCop
      end
    end
  end
end
