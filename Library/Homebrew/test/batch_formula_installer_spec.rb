require "batch_formula_installer"

describe BatchFormulaInstaller do
  it "initializes with formulae" do
    BatchFormulaInstaller.new([double("FormulaInstaller 1")])
  end

  describe "#install" do
    it "calls install on a FormulaInstaller for each Formula" do
      formula_installer = double("FormulaInstaller")

      expect(formula_installer).to receive(:install)
      BatchFormulaInstaller.new([formula_installer]).install
    end
  end
end
