require "rails_helper"

RSpec.describe Events::ReproductiveTransitionValidator do
  describe "#validate!" do
    context "heat_detection" do
      it "é válido quando cow está open" do
        cow = instance_double(
          Cow,
          reproductive_open?: true,
          reproductive_postpartum?: false,
          reproductive_in_heat?: false
        )

        validator = described_class.new(
          cow: cow,
          event_type: "heat_detection"
        )

        expect(validator.validate!).to eq(true)
      end

      it "é inválido quando cow não está em estado permitido" do
        cow = instance_double(
          Cow,
          reproductive_open?: false,
          reproductive_postpartum?: false,
          reproductive_in_heat?: false
        )

        validator = described_class.new(
          cow: cow,
          event_type: "heat_detection"
        )

        expect { validator.validate! }
          .to raise_error(Events::Error, I18n.t!("events.errors.invalid_heat_detection_transition"))
      end
    end

    context "insemination" do
      it "é válido quando cow está in_heat" do
        cow = instance_double(Cow, reproductive_in_heat?: true)

        validator = described_class.new(
          cow: cow,
          event_type: "insemination"
        )

        expect(validator.validate!).to eq(true)
      end

      it "é inválido quando cow não está in_heat" do
        cow = instance_double(Cow, reproductive_in_heat?: false)

        validator = described_class.new(
          cow: cow,
          event_type: "insemination"
        )

        expect { validator.validate! }
          .to raise_error(Events::Error, I18n.t!("events.errors.invalid_insemination_transition"))
      end
    end

    context "pregnancy_check" do
      it "é válido quando cow está inseminated" do
        cow = instance_double(Cow, reproductive_inseminated?: true)

        validator = described_class.new(
          cow: cow,
          event_type: "pregnancy_check"
        )

        expect(validator.validate!).to eq(true)
      end

      it "é inválido quando cow não está inseminated" do
        cow = instance_double(Cow, reproductive_inseminated?: false)

        validator = described_class.new(
          cow: cow,
          event_type: "pregnancy_check"
        )

        expect { validator.validate! }
          .to raise_error(Events::Error, I18n.t!("events.errors.invalid_pregnancy_check_transition"))
      end
    end

    context "calving" do
      it "é válido quando cow está pregnant" do
        cow = instance_double(Cow, reproductive_pregnant?: true)

        validator = described_class.new(
          cow: cow,
          event_type: "calving"
        )

        expect(validator.validate!).to eq(true)
      end

      it "é inválido quando cow não está pregnant" do
        cow = instance_double(Cow, reproductive_pregnant?: false)

        validator = described_class.new(
          cow: cow,
          event_type: "calving"
        )

        expect { validator.validate! }
          .to raise_error(Events::Error, I18n.t!("events.errors.invalid_calving_transition"))
      end
    end

    context "quando evento não é reprodutivo" do
      it "ignora validação" do
        cow = instance_double(Cow)

        validator = described_class.new(
          cow: cow,
          event_type: "weighing"
        )

        expect(validator.validate!).to eq(true)
      end
    end
  end
end
