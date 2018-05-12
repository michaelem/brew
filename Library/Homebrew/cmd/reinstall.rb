#:  * `reinstall` <formula>:
#:    Uninstall and then install <formula> (with existing install options).

require "formula_installer"
require "batch_formula_installer"
require "development_tools"

module Homebrew
  module_function

  def reinstall
    FormulaInstaller.prevent_build_flags unless DevelopmentTools.installed?

    formulae           = ARGV.resolved_formulae
    formula_installers = []

    formulae.each do |f|
      if f.pinned?
        onoe "#{f.full_name} is pinned. You must unpin it to reinstall."
        next
      end
      formula_installers << prepare_formula_installer(f)
    end

    begin
    batch_formula_installer = BatchFormulaInstaller.new(formula_installers)
    batch_formula_installer.install
    rescue FormulaInstallationAlreadyAttemptedError
      nil
    rescue Exception # rubocop:disable Lint/RescueException
      ignore_interrupts { restore_backup(batch_formula_installer.keg, batch_formula_installer.keg_was_linked) }
      raise
    else
      backup_path(batch_formula_installer.keg).rmtree if backup_path(batch_formula_installer.keg).exist?
    end
  end

  def prepare_formula_installer(f)
    build_options = BuildOptions.new(Options.create(ARGV.flags_only), f.options)
    options = build_options.used_options
    options |= f.build.used_options
    options &= f.options

    fi = FormulaInstaller.new(f)
    fi.options              = options
    fi.invalid_option_names = build_options.invalid_option_names
    fi.build_bottle         = ARGV.build_bottle? || (!f.bottled? && f.build.bottle?)
    fi.interactive          = ARGV.interactive?
    fi.git                  = ARGV.git?
    fi.link_keg           ||= keg_was_linked if f.opt_prefix.directory?

    oh1 "Reinstalling #{Formatter.identifier(f.full_name)} #{options.to_a.join " "}"
    fi
  end

  def restore_backup(keg, keg_was_linked)
    path = backup_path(keg)

    return unless path.directory?

    Pathname.new(keg).rmtree if keg.exist?

    path.rename keg
    keg.link if keg_was_linked
  end

  def backup_path(path)
    Pathname.new "#{path}.reinstall"
  end
end
