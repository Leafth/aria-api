require "rails_helper"

RSpec.describe Events::ReproductiveTransitionValidator do
  def build_cow(**attrs)
    instance_double(
      Cow, { active?: true }.merge(attrs)
    )
  end

  def validate(cow, event_type)
    described_class.new(
      cow: cow,
      event_type: event_type
    ).validate!
  end

  describe "#validate!" do
    context "heat_detection" do
      it "é válido quando cow está open" do
        cow = build_cow(
          reproductive_open?: true,
          reproductive_postpartum?: false
        )

        expect(validate(cow, "heat_detection")).to eq(true)
      end

      it "é inválido quando cow não está em estado permitido" do
        cow = build_cow(
          reproductive_open?: false,
          reproductive_postpartum?: false
        )

        expect {
          validate(cow, "heat_detection")
        }.to raise_error(
          Events::Error,
          I18n.t!("events.errors.invalid_heat_detection_transition")
        )
      end
    end

    context "insemination" do
      it "é válido quando cow está in_heat" do
        cow = build_cow(reproductive_in_heat?: true)

        expect(validate(cow, "insemination")).to eq(true)
      end

      it "é inválido quando cow não está in_heat" do
        cow = build_cow(reproductive_in_heat?: false)

        expect {
          validate(cow, "insemination")
        }.to raise_error(
          Events::Error,
          I18n.t!("events.errors.invalid_insemination_transition")
        )
      end
    end

    context "pregnancy_check" do
      it "é válido quando cow está inseminated" do
        cow = build_cow(reproductive_inseminated?: true)

        expect(validate(cow, "pregnancy_check")).to eq(true)
      end

      it "é inválido quando cow não está inseminated" do
        cow = build_cow(reproductive_inseminated?: false)

        expect {
          validate(cow, "pregnancy_check")
        }.to raise_error(
          Events::Error,
          I18n.t!("events.errors.invalid_pregnancy_check_transition")
        )
      end
    end

    context "calving" do
      it "é válido quando cow está pregnant" do
        cow = build_cow(reproductive_pregnant?: true)

        expect(validate(cow, "calving")).to eq(true)
      end

      it "é inválido quando cow não está pregnant" do
        cow = build_cow(reproductive_pregnant?: false)

        expect {
          validate(cow, "calving")
        }.to raise_error(
          Events::Error,
          I18n.t!("events.errors.invalid_calving_transition")
        )
      end
    end

    context "pregnancy_interruption" do
      it "é válido quando cow está pregnant" do
        cow = build_cow(reproductive_pregnant?: true)

        expect(validate(cow, "pregnancy_interruption")).to eq(true)
      end

      it "é inválido quando cow não está pregnant" do
        cow = build_cow(reproductive_pregnant?: false)

        expect {
          validate(cow, "pregnancy_interruption")
        }.to raise_error(
          Events::Error,
          I18n.t!("events.errors.invalid_pregnancy_interruption_transition")
        )
      end
    end

    context "quando matriz é inativa" do
      it "ignora validação" do
        cow = build_cow(active?: false)

        expect {
          validate(cow, "weighing")
        }.to raise_error(
          Events::Error,
          I18n.t!("cows.errors.cow_inactive")
        )
      end
    end

    context "quando evento não é reprodutivo" do
      it "ignora validação" do
        cow = build_cow

        expect(validate(cow, "weighing")).to eq(true)
      end
    end
  end
end
