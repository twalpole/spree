require 'spec_helper'

describe 'Address', type: :feature, inaccessible: true do
  stub_authorization!

  after do
    Capybara.ignore_hidden_elements = true
  end

  before do
    create(:product, name: 'RoR Mug')
    create(:order_with_totals, state: 'cart')

    Capybara.ignore_hidden_elements = false

    visit spree.root_path

    add_to_cart('RoR Mug')

    address = 'order_bill_address_attributes'
    @country_css = "#{address}_country_id"
    @state_select_css = "##{address}_state_id"
    @state_name_css = "##{address}_state_name"
  end

  context 'country requires state', js: true do
    let!(:canada) { create(:country, name: 'Canada', states_required: true, iso: 'CA') }
    let!(:uk) { create(:country, name: 'United Kingdom', states_required: true, iso: 'UK') }

    before { Spree::Config[:default_country_id] = uk.id }

    context 'but has no state' do
      it 'shows the state input field' do
        click_button 'Checkout'

        select canada.name, from: @country_css
        expect(page).to have_selector(@state_select_css, visible: :hidden)
        expect(page).to have_selector(@state_name_css, visible: true)
        expect(page).to have_css(@state_name_css, class: ['!hidden'])
        expect(page).to have_css(@state_name_css, class: ['required'])
        expect(page).to have_css(@state_select_css, class: ['!required'])
        expect(page).not_to have_selector("input#{@state_name_css}[disabled]")
      end
    end

    context 'and has state' do
      before { create(:state, name: 'Ontario', country: canada) }

      it 'shows the state collection selection' do
        click_button 'Checkout'

        select canada.name, from: @country_css
        expect(page).to have_selector(@state_select_css, visible: true)
        expect(page).to have_selector(@state_name_css, visible: :hidden)
        expect(page).to have_css(@state_select_css, class: ['required'])
        expect(page).to have_css(@state_select_css, class: ['!hidden'])
        expect(page).to have_css(@state_name_css, class: ['!required'])
      end
    end

    context 'user changes to country without states required' do
      let!(:france) { create(:country, name: 'France', states_required: false, iso: 'FRA') }

      it 'clears the state name' do
        skip 'This is failing on the CI server, but not when you run the tests manually... It also does not fail locally on a machine.'
        click_button 'Checkout'
        select canada.name, from: @country_css
        page.find(@state_name_css).set('Toscana')

        select france.name, from: @country_css
        expect(page).to have_css(@state_name_css, exact_text: '')
        until page.evaluate_script('$.active').to_i.zero?
          expect(page).to have_css(@state_name_css, class: ['!hidden'])
          expect(page).to have_css(@state_name_css, class: ['!required'])
          expect(page).to have_css(@state_select_css, class: ['!required'])
        end
      end
    end
  end

  context 'country does not require state', js: true do
    let!(:france) { create(:country, name: 'France', states_required: false, iso: 'FRA') }

    it 'shows a disabled state input field' do
      click_button 'Checkout'

      select france.name, from: @country_css
      expect(page).to have_selector(@state_select_css, visible: :hidden)
      expect(page).to have_selector(@state_name_css, visible: :hidden)
    end
  end
end
