require "rails_helper"

RSpec.describe Cows::Insights::ReproductiveStatus do
  let(:cow) do
    create(
      :cow,
      :young,
      reproductive_status: reproductive_status,
      last_heat_at: last_heat_at,
      last_insemination_at: last_insemination_at,
      pregnancy_confirmed_at: pregnancy_confirmed_at,
      last_calving_at: last_calving_at,
      last_pregnancy_interruption_at: last_pregnancy_interruption_at
    )
  end

  let(:reproductive_status) { :open }
  let(:last_heat_at) { nil }
  let(:last_insemination_at) { nil }
  let(:pregnancy_confirmed_at) { nil }
  let(:last_calving_at) { nil }
  let(:last_pregnancy_interruption_at) { nil }


  def call_service
    described_class.new(cow: cow).call
  end

  describe "#call" do
    context "quando a matriz está aguardando cio" do
      let(:reproductive_status) { :open }

      context "sem data de cio anterior" do
        it "retorna mensagem e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "open",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.open"),
            observation: nil,
            alerts: []
          )
        end
      end

      context "e teve parto interrompido recentemente" do
        let(:last_heat_at) { 50.days.ago.change(usec: 0) }
        let(:last_pregnancy_interruption_at) { 3.days.ago.change(usec: 0) }

        it "retorna mensagem e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "open",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.open"),
            observation: nil,
            alerts: []
          )
        end
      end

      context "com próximo cio ainda dentro do prazo" do
        let(:last_heat_at) { 10.days.ago.change(usec: 0) }

        it "retorna a data estimada do próximo cio e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "open",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.open"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.open",
              next_heat_date: I18n.l(expected_next_heat_date)
            ),
            alerts: []
          )
        end
      end

      context "com cio previsto já atrasado" do
        let(:last_heat_at) { 22.days.ago.change(usec: 0) }

        it "retorna alerta de cio atrasado" do
          result = call_service

          expect(result).to eq(
            status: "open",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.open"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.open",
              next_heat_date: I18n.l(expected_next_heat_date)
            ),
            alerts: [
              {
                level: "warning",
                code: "heat_overdue",
                message: I18n.t!("cows.insights.profile.reproductive_status.alerts.heat_overdue")
              }
            ]
          )
        end
      end
    end

    context "quando a matriz está em cio" do
      let(:reproductive_status) { :in_heat }

      context "com cio ativo e longe do fim" do
        let(:last_heat_at) { 10.hours.ago.change(usec: 0) }

        it "retorna observação e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "in_heat",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.in_heat"),
            observation: I18n.t!("cows.insights.profile.reproductive_status.observations.in_heat"),
            alerts: []
          )
        end
      end

      context "com cio perto do fim" do
        let(:last_heat_at) { 20.hours.ago.change(usec: 0) }

        it "retorna alerta de cio próximo do fim" do
          result = call_service
          remaining_hours = ((last_heat_at + 24.hours - Time.current) / 1.hour).ceil

          expect(result).to eq(
            status: "in_heat",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.in_heat"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.in_heat",
              remaining_hours: remaining_hours
            ),
            alerts: [
              {
                level: "warning",
                code: "heat_ending_soon",
                message: I18n.t!(
                  "cows.insights.profile.reproductive_status.alerts.heat_ending_soon",
                  remaining_hours: remaining_hours
                )
              }
            ]
          )
        end
      end

      context "com cio expirado" do
        let(:last_heat_at) { 25.hours.ago.change(usec: 0) }

        it "retorna observação de cio expirado e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "in_heat",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.in_heat"),
            observation: I18n.t!("cows.insights.profile.reproductive_status.observations.heat_expired"),
            alerts: []
          )
        end
      end
    end

    context "quando a matriz está inseminada" do
      let(:reproductive_status) { :inseminated }

      context "antes do período de diagnóstico" do
        let(:last_insemination_at) { 10.days.ago.change(usec: 0) }

        it "retorna observação de aguardando diagnóstico e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "inseminated",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.inseminated"),
            observation: I18n.t!("cows.insights.profile.reproductive_status.observations.inseminated"),
            alerts: []
          )
        end
      end

      context "entre 20 e 30 dias após inseminação" do
        let(:last_insemination_at) { 20.days.ago.change(usec: 0) }

        it "retorna alerta de diagnóstico indicado" do
          result = call_service

          expect(result).to eq(
            status: "inseminated",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.inseminated"),
            observation: I18n.t!("cows.insights.profile.reproductive_status.observations.inseminated"),
            alerts: [
              {
                level: "warning",
                code: "pregnancy_check_due",
                message: I18n.t!("cows.insights.profile.reproductive_status.alerts.pregnancy_check_due")
              }
            ]
          )
        end
      end

      context "mais de 30 dias após inseminação" do
        let(:last_insemination_at) { 31.days.ago.change(usec: 0) }

        it "retorna alerta de diagnóstico atrasado" do
          result = call_service

          expect(result).to eq(
            status: "inseminated",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.inseminated"),
            observation: I18n.t!("cows.insights.profile.reproductive_status.observations.inseminated"),
            alerts: [
              {
                level: "danger",
                code: "pregnancy_check_overdue",
                message: I18n.t!("cows.insights.profile.reproductive_status.alerts.pregnancy_check_overdue")
              }
            ]
          )
        end
      end
    end

    context "quando a matriz está prenha" do
      let(:reproductive_status) { :pregnant }
      let(:pregnancy_confirmed_at) { 30.days.ago.change(usec: 0) }

      context "antes da fase final da gestação" do
        let(:last_insemination_at) { 100.days.ago.change(usec: 0) }

        it "retorna data prevista do parto e nenhum alerta" do
          result = call_service

          expect(result).to eq(
            status: "pregnant",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.pregnant"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.pregnant",
              calving_date: I18n.l(expected_calving_date)
            ),
            alerts: []
          )
        end
      end

      context "com parto previsto para os próximos 20 dias" do
        let(:last_insemination_at) { 270.days.ago.change(usec: 0) }

        it "retorna alerta de parto próximo" do
          result = call_service

          expect(result).to eq(
            status: "pregnant",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.pregnant"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.pregnant",
              calving_date: I18n.l(expected_calving_date)
            ),
            alerts: [
              {
                level: "warning",
                code: "calving_due_soon",
                message: I18n.t!("cows.insights.profile.reproductive_status.alerts.calving_due_soon")
              }
            ]
          )
        end
      end

      context "com parto atrasado" do
        let(:last_insemination_at) { 286.days.ago.change(usec: 0) }

        it "retorna alerta de parto atrasado" do
          result = call_service

          expect(result).to eq(
            status: "pregnant",
            message: I18n.t!("cows.insights.profile.reproductive_status.messages.pregnant"),
            observation: I18n.t!(
              "cows.insights.profile.reproductive_status.observations.pregnant",
              calving_date: I18n.l(expected_calving_date)
            ),
            alerts: [
              {
                level: "danger",
                code: "calving_overdue",
                message: I18n.t!("cows.insights.profile.reproductive_status.alerts.calving_overdue")
              }
            ]
          )
        end
      end
    end

    context "quando a matriz está em pós-parto" do
      let(:reproductive_status) { :postpartum }
      let(:last_calving_at) { 3.days.ago.change(usec: 0) }

      it "retorna data do parto e nenhum alerta" do
        result = call_service
        days_since_calving = (Time.zone.today - cow.last_calving_at.to_date).to_i

        expect(result).to eq(
          status: "postpartum",
          message: I18n.t!("cows.insights.profile.reproductive_status.messages.postpartum"),
          observation: I18n.t!(
            "cows.insights.profile.reproductive_status.observations.postpartum",
            days_since_calving: days_since_calving
          ),
          alerts: []
        )
      end
    end
  end

  def expected_next_heat_date
    last_heat_at.to_date + 21.days
  end

  def expected_calving_date
    last_insemination_at.to_date + 285.days
  end
end
