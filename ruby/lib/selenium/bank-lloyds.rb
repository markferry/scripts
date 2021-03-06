require File.expand_path('~/Repos/scripts/ruby/lib/utilities.rb')
require File.expand_path('~/Repos/scripts/ruby/lib/selenium/bank-common.rb')

class BankLloyds
    include CommandLineReporter

    def initialize(username, password, security, displays = 'single', headless = false, displayProgress = false, databaseConnection = nil)
        @username = username
        @password = password
        @security = security
        @displays = displays
        @headless = headless
        @displayProgress = displayProgress
        @login_uri = 'https://online.lloydsbank.co.uk/personal/logon/login.jsp'
        @databaseConnection = databaseConnection
    end

    # Gets you as far as Lloyds account overview screen & then returns the browser for (possible) further manipulation.
    def login(browser = getBrowser(@displays, @headless))
        if @displayProgress
            puts "\x1B[90mAttempting to establish connection with: #{@login_uri}\x1B[0m"
        end
        browser.goto(@login_uri)
        browser.text_field(:name => 'frmLogin:strCustomerLogin_userID').set @username
        browser.text_field(:name => 'frmLogin:strCustomerLogin_pwd').set @password
        browser.checkbox(:name => 'frmLogin:loginRemember').set
        browser.input(:id => 'frmLogin:btnLogin1').click
        if @displayProgress
            puts "\x1B[90mSuccessfully bypassed first page\x1B[0m"
        end
        browser.select_list(:name => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo1').option(:value => "&nbsp;#{getCharAt(browser.label(:for => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo1').when_present(5).text.gsub(/[^0-9]/, ''), @security)}").select
        browser.select_list(:name => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo2').option(:value => "&nbsp;#{getCharAt(browser.label(:for => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo2').when_present(5).text.gsub(/[^0-9]/, ''), @security)}").select
        browser.select_list(:name => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo3').option(:value => "&nbsp;#{getCharAt(browser.label(:for => 'frmentermemorableinformation1:strEnterMemorableInformation_memInfo3').when_present(5).text.gsub(/[^0-9]/, ''), @security)}").select
        browser.input(:id => 'frmentermemorableinformation1:btnContinue').click
        until browser.link(:title => 'View the latest transactions on your Lloyds Account').exists? do
            # Email Confirmation Page
            if browser.input(:id => 'frm2:btnContinue2', :type => 'image').exists?
                browser.input(:id => 'frm2:btnContinue2', :type => 'image').click
                if @displayProgress
                    puts "\x1B[90mSuccessfully bypassed (occasional) email confirmation page\x1B[0m\n"
                end
            end
            # Offers Page
            if browser.link(:title => 'Not right now').exists?
                browser.link(:title => 'Not right now').click
                if @displayProgress
                    puts "\x1B[90mSuccessfully bypassed (occasional) offers page\x1B[0m\n"
                end
            end
            # Occasional 'Important Update' Page
            if browser.checkbox(:id => 'frmmandatoryMsgs:msgList1:0:chktmpMsgRead1').exists?
                browser.checkbox(:id => 'frmmandatoryMsgs:msgList1:0:chktmpMsgRead1').set
                if @displayProgress
                    puts "\x1B[90mTicked checkbox to confirm I've read a message\x1B[0m\n"
                end
            end
            if browser.checkbox(:id => 'frmmandatoryMsgs:tmpAllMsgsRead').exists?
                browser.checkbox(:id => 'frmmandatoryMsgs:tmpAllMsgsRead').set
                if @displayProgress
                    puts "\x1B[90mTicked checkbox to never show a message again\x1B[0m\n"
                end
            end
            if browser.input(:id => 'frmmandatoryMsgs:continue_to_your_accounts2').exists?
                browser.input(:id => 'frmmandatoryMsgs:continue_to_your_accounts2').click
                if @displayProgress
                    puts "\x1B[90mSuccessfully bypassed (occasional) important information page\x1B[0m\n"
                end
            end
            if browser.li(:class => 'primaryAction').link(:index => 0).exists?
                browser.li(:class => 'primaryAction').link(:index => 0).click
                if @displayProgress
                    puts "\x1B[90mSuccessfully bypassed (occasional) offers page\x1B[0m\n"
                end
            end
        end
        if @displayProgress
            puts "\x1B[90mSuccessfully logged in to Lloyds\x1B[0m\n"
        end
        sleep(2)
        browser
    end

    def runExtraction(showInTerminal = false)
        attempt = 0
        succeeded = false
        while !succeeded
            begin
                attempt = attempt + 1
                data = getAllData(showInTerminal)
                data[0].close
                data = data[1]
            rescue Exception => e
                succeeded = false
                if showInTerminal
                    puts "\x1B[31mAttempt #{attempt} failed with message: \x1B[90m#{e.message}.\x1B[0m"
                    cronLog"Lloyds: Attempt #{attempt} failed with message: #{e.message}."
                end
            else
                succeeded = true
            ensure
                if succeeded

                    @databaseConnection.query("INSERT INTO bank_account_type_credit_card (bank_account_id, balance, balance_available, balance_limit, date_fetched, date_fetched_string, minimum_payment, minimum_payment_date) VALUES (7, #{data['cc_balance']}, #{data['cc_available']}, #{data['cc_limit']}, '#{DateTime.now}', '#{DateTime.now}', #{data['cc_minimum_payment']}, '#{data['cc_due_date'].nil? ? '0000-00-00' : data['cc_due_date']}')")
                    @databaseConnection.query("INSERT INTO bank_account_type_bank_account (bank_account_id, balance, balance_available, balance_overdraft, date_fetched, date_fetched_string) VALUES (8, #{data['account_1_balance']}, #{data['account_1_available']}, #{data['account_1_overdraft']}, '#{DateTime.now}', '#{DateTime.now}')")
                    BankCommon.new.insertTransactions(@databaseConnection, data['cc_transactions'], 7)
                    BankCommon.new.insertTransactions(@databaseConnection, data['account_1_transactions'], 8)
                    # Check if existing transactions (in last month) still exist
                    objectData = Array[
                        {:bank_account_id => 7, :transactions => data['cc_transactions']},
                        {:bank_account_id => 8, :transactions => data['account_1_transactions']},
                    ]
                    BankCommon.new.checkIfTransactionStillExist(@databaseConnection, objectData)
                    if showInTerminal
                        puts "\x1B[32mSuccess (Lloyds)\x1B[0m"
                    end

                else
                    if attempt >= 5
                        succeeded = true
                        if showInTerminal
                            puts "\x1B[31mSite is either down or there is an error in the Lloyds script.\x1B[0m"
                        end
                    end
                end
            end
        end
    end

    def getBalances(showInTerminal = false, browser = self.login)
        data = {}
        data_credit_card = Array.new

        # Get Current Account Data
        browser.link(:id => 'lstAccLst:0:lkImageRetail1').when_present(5).click
        data['account_1_balance'] = cleanCurrency(browser.p(:class => 'balance', :index => 0).when_present(5).text)
        data['account_1_available'] = browser.div(:class => 'accountBalance', :index => 0).text.split(':')
        data['account_1_available'] = data['account_1_available'][1].split('[')
        data['account_1_available'] = cleanCurrency(data['account_1_available'][0].strip)
        data['account_1_overdraft'] = browser.p(:class => 'accountMsg', :index => 1).text
        data['account_1_overdraft'] = data['account_1_overdraft'].split
        data['account_1_overdraft'] = cleanCurrency(data['account_1_overdraft'][data['account_1_overdraft'].count - 1])
        if showInTerminal
            puts "\x1B[90mSuccessfully retrieved balances for \x1B[33mCurrent Account\x1B[0m"
        end
        data_current = getTransactionsFromTable(browser.table(:id => 'pnlgrpStatement:conS1:tblTransactionListView').when_present(5))
        if browser.input(:type => 'image', :title => 'Previous').exists?
            browser.input(:type => 'image', :title => 'Previous').click
            data_current.push(*getTransactionsFromTable(browser.table(:id => 'pnlgrpStatement:conS1:tblTransactionListView').when_present(5)))
        end
        if showInTerminal
            puts "\x1B[90mSuccessfully retrieved transactions for \x1B[33mCurrent Account\x1B[0m"
        end

        # Get Credit Card Data
        browser.link(:id => 'lkAccOverView_retail').when_present(5).click
        browser.link(:title => 'View the latest transactions on your Lloyds Bank Platinum MasterCard').when_present(5).click
        data['cc_available'] = browser.p(:class => 'accountMsg', :index => 0).when_present(5).text
        data['cc_available'] = data['cc_available'].split(':')
        data['cc_available'] = cleanCurrency(data['cc_available'][data['cc_available'].count - 1])
        data['cc_limit'] = browser.p(:class => 'accountMsg', :index => 1).when_present(5).text
        data['cc_limit'] = data['cc_limit'].split(':')
        data['cc_limit'] = cleanCurrency(data['cc_limit'][data['cc_limit'].count - 1])
        data['cc_balance'] = cleanCurrency((data['cc_limit'] - data['cc_available']).to_s)
        data['cc_minimum_payment'] = browser.div(:class => 'creditCardStatementDetails clearfix').when_present(5).div(:class => 'numbers').p(:index => 1).text.split
        data['cc_minimum_payment'] = cleanCurrency(data['cc_minimum_payment'][data['cc_minimum_payment'].count - 1])
        data['cc_due_date'] = browser.div(:class => 'creditCardStatementDetails clearfix').div(:class => 'payment').p(:index => 0).strong.text
        data['cc_due_date'] = data['cc_due_date'].split(':')

        begin
            data['cc_due_date'] = DateTime.strptime(data['cc_due_date'][data['cc_due_date'].count - 1].lstrip.rstrip, '%d %B %Y').strftime('%Y-%m-%d')
        rescue Exception => e
            data['cc_due_date'] = nil
        end

        if showInTerminal
            puts "\x1B[90mSuccessfully retrieved balances for \x1B[36mPlatinum Mastercard\x1B[0m"
        end
        if browser.table(:id => 'pnlgrpStatement:conS2:tblTransactionListCreditCard').exists?
            data_credit_card = getTransactionsFromTableCreditCard(browser.table(:id => 'pnlgrpStatement:conS2:tblTransactionListCreditCard'))
        end
        if browser.input(:type => 'image', :title => 'Previous month').exists?
            browser.input(:type => 'image', :title => 'Previous month').click
            if browser.table(:id => 'pnlgrpStatement:conS2:tblTransactionListCreditCard').exists?
                data_credit_card.push(*getTransactionsFromTableCreditCard(browser.table(:id => 'pnlgrpStatement:conS2:tblTransactionListCreditCard')))
            end
        end
        if showInTerminal
            puts "\x1B[90mSuccessfully retrieved transactions for \x1B[36mPlatinum Mastercard\x1B[0m"
        end

        # Add transactions to final array
        data['account_1_transactions'] = data_current
        data['cc_transactions'] = data_credit_card

        Array[browser, data]
    end

    def getAllData(showInTerminal = false, browser = self.login)
        # Get balances first
        data = getBalances(showInTerminal, browser)
        data = data[1]
        Array[browser, data]
    end

    # Takes table and gets transactions from that.
    def getTransactionsFromTable(table)
        rowCount = 0
        transactions = Array.new
        table.rows.each do |tableRow|
            rowCount = rowCount + 1
            if rowCount <= 1
                next
            end
            rowData = {}
            cellCount = 0
            tableRow.cells.each do |tableCell|
                cellCount = cellCount + 1
                if cellCount == 1
                    rowData['date'] = tableCell.text
                elsif cellCount == 2
                    rowData['description'] = tableCell.text
                elsif cellCount == 3
                    rowData['type'] = tableCell.text
                elsif cellCount == 4
                    rowData['paid_in'] = tableCell.text
                elsif cellCount == 5
                    rowData['paid_out'] = tableCell.text
                elsif cellCount == 6
                    rowData['balance'] = tableCell.text
                end
            end
            transactions << rowData
        end
        sanitizeTransactions(transactions)
    end

    # Takes transaction data and sanitizes it.
    def sanitizeTransactions(transactions)
        sanitizedArray = Array.new
        transactions.each do |transaction|
            newData = {}
            # Date
            date = Date.parse(transaction['date'])
            newData['date'] = date.strftime('%Y-%m-%d')
            # Type
            newData['type'] = transaction['type']
            # Description
            newData['description'] = transaction['description']
            # Paid In/Out
            newData['paid_in'] = transaction['paid_in'].delete(',').to_f
            newData['paid_out'] = transaction['paid_out'].delete(',').to_f
            newData['balance'] = transaction['balance'].delete(',').to_f
            sanitizedArray << newData
        end
        sanitizedArray
    end

    # Takes table and gets transactions from that.
    def getTransactionsFromTableCreditCard(table)
        rowCount = 0
        transactions = Array.new
        table.rows.each do |tableRow|
            rowCount = rowCount + 1
            if rowCount <= 2
                next
            end
            rowData = {}
            cellCount = 0
            tableRow.cells.each do |tableCell|

                # If no transactions, break out of loop immediately.
                if tableCell.text.include? "we can't display your statement transactions"
                    break;
                elsif tableCell.text.include? 'Please try again later'
                    break;
                end

                cellCount = cellCount + 1
                if cellCount == 1
                    rowData['date'] = tableCell.text
                elsif cellCount == 2
                    rowData['description'] = tableCell.text
                elsif cellCount == 3
                    rowData['reference'] = tableCell.text
                elsif cellCount == 5
                    rowData['paid_out'] = tableCell.text
                end
            end
            transactions << rowData
        end
        sanitizeTransactionsCreditCard(transactions)
    end

    # Takes transaction data and sanitizes it.
    def sanitizeTransactionsCreditCard(transactions)
        sanitizedArray = Array.new
        transactions.each do |transaction|
            newData = {}
            # Date
            date = Date.parse(transaction['date'])
            newData['date'] = date.strftime('%Y-%m-%d')
            # Type
            newData['type'] = 'CC'
            # Description
            newData['description'] = "#{transaction['description']} Ref ##{transaction['reference']}"
            # Paid In/Out
            if transaction['paid_out'].include? 'CR'
                paidSplit = transaction['paid_out'].split(' ')
                newData['paid_in'] = paidSplit[0].delete(',').to_f
                newData['paid_out'] = 0.to_f
            else
                newData['paid_in'] = 0.to_f
                newData['paid_out'] = transaction['paid_out'].delete(',').to_f
            end

            # As this doesn't display a balance, use the last 6 digits of reference as a pseudo-balance.
            balance = transaction['reference']
            balance = balance[-6..-1] || balance
            newData['balance'] = balance.to_f

            sanitizedArray << newData
        end
        sanitizedArray
    end

end