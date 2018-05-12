class BatchFormulaInstaller
  attr_reader :formula_installers, :keg, :keg_was_linked

  def initialize(formula_installers)
    @formula_installers = formula_installers
  end

  def install
    @formula_installers.each do |formula_installer|
      formula = formula_installer.formula
      if formula.opt_prefix.directory?
        @keg            = Keg.new(formula.opt_prefix.resolved_path)
        @keg_was_linked = keg.linked?
        backup
      end
      Migrator.migrate_if_needed(formula)
      formula_installer.install
    end
    print_caveats
  end

private

  def backup
    @keg.unlink
    @keg.rename backup_path(@keg)
  end

  def print_caveats
    @formula_installers.map(&:caveats)
  end

  def backup_path(path)
    Pathname.new "#{path}.reinstall"
  end
end
