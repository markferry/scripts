require '/Users/Albert/Repos/Scripts/ruby/lib/utilities.rb'

class BankNatWest
    include CommandLineReporter

    def initialize(username, security_top, security_bottom, displays = 'single', headless = false, displayProgress = false)
        @username = username
        @security_top = security_top
        @security_bottom = security_bottom
        @displays = displays
        @headless = headless
        @displayProgress = displayProgress
        @login_uri = 'https://www.nwolb.com/default.aspx'
    end

    # Gets you as far as NatWest account overview screen & then returns the browser for (possible) further manipulation.
    def login(browser = getBrowser(@displays, @headless))
        f = 'ctl00_secframe'
        if @displayProgress
            puts "\x1B[90mAttempting to establish connection with: #{@login_uri}\x1B[0m"
        end
        browser.goto(@login_uri)
        browser.frame(:id => f).text_field(:name => 'ctl00$mainContent$LI5TABA$DBID_edit').set @username
        browser.frame(:id => f).checkbox(:id => 'ctl00_mainContent_LI5TABA_LI5CBB').set
        browser.frame(:id => f).input(:id => 'ctl00_mainContent_LI5TABA_LI5-LBA_button_button').click
        if @displayProgress
            puts "\x1B[90mSuccessfully bypassed first page\x1B[0m"
        end
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPEA_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALALabel').text.gsub(/[^0-9]/, ''), @security_top)
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPEB_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALBLabel').text.gsub(/[^0-9]/, ''), @security_top)
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPEC_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALCLabel').text.gsub(/[^0-9]/, ''), @security_top)
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPED_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALDLabel').text.gsub(/[^0-9]/, ''), @security_bottom)
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPEE_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALELabel').text.gsub(/[^0-9]/, ''), @security_bottom)
        browser.frame(:id => f).text_field(:id => 'ctl00_mainContent_Tab1_LI6PPEF_edit').set getCharAt(browser.frame(:id => f).label(:id => 'ctl00_mainContent_Tab1_LI6DDALFLabel').text.gsub(/[^0-9]/, ''), @security_bottom)
        browser.frame(:id => f).checkbox(:id => 'TimeoutCheckbox-LI6CBA').set
        browser.frame(:id => f).input(:id => 'ctl00_mainContent_Tab1_next_text_button_button').click
        # Occasional 'Important Information' Page
        if browser.frame(:id => f).checkbox(:id => 'ctl00_mainContent_LI1CBA').exists?
            browser.frame(:id => f).checkbox(:id => 'ctl00_mainContent_LI1CBA').set
            browser.frame(:id => f).input(:id => 'ctl00$mainContent$FinishButton_button').click
            if @displayProgress
                puts "\x1B[90mSuccessfully bypassed (occasional) important information page\x1B[0m\n"
            end
        end
        if @displayProgress
            puts "\x1B[90mSuccessfully logged in to NatWest\x1B[0m\n"
        end
        browser
    end

    def getBalances(showInTerminal = false, browser = self.login)
        f = 'ctl00_secframe'
        data = {}
        data['advantage_gold'] = browser.frame(:id => f).tr(:id => 'Account_A412AD6062AE989A9FCDAEB7D9ED8A594808AC87').td(:class => 'currency', :index => 1).text.delete('£').delete(',').to_f
        data['savings_account'] = browser.frame(:id => f).tr(:id => 'Account_CE99D6FF6219B59BB28B6A42825D98D60B92326C').td(:class => 'currency', :index => 1).text.delete('£').delete(',').to_f
        data['step_account'] = browser.frame(:id => f).tr(:id => 'Account_FAB7EFB59260BED0F1081E761570BF4227C37E6B').td(:class => 'currency', :index => 1).text.delete('£').delete(',').to_f
        if showInTerminal
            puts "\n[ #{Rainbow('NatWest').foreground('#ff008a')} ]"
            table(:border => true) do
                row do
                    column('Advantage Gold', :width => 19, :align => 'right')
                    column('Step Account', :width => 19, :align => 'right')
                    column('Savings Account', :width => 19, :align => 'right')
                end
                row do
                    column("#{toCurrency(data['advantage_gold'])}", :color => (data['advantage_gold'] >= 0) ? 'green' : 'red')
                    column("#{toCurrency(data['step_account'])}", :color => (data['step_account'] >= 0) ? 'green' : 'red')
                    column("#{toCurrency(data['savings_account'])}", :color => (data['savings_account'] >= 0) ? 'green' : 'red')
                end
            end
        end
        Array[browser, data]
    end
end