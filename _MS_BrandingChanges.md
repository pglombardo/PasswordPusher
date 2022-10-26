############ Imagery ############

	## TODO: 
	## I had initially replaced all iconography at \app\frontend\img
	## with built-in branding I need to see if this is still needed
	##

\app\frontend\img
	ALL android-icon
	ALL apple-icon
	ALL favicons with specified size
	ALL Logo images (leave pwpush_logo.png)
	essentially all except 
		apple-touch-*
		button-*
		favicon.ico
		forkme.png
		pwpush_logo.png




############ Password Generator Presets ############

	## TODO: 
	## 	Verify if this can be adjusted in config/settings for instance 
	## 	https://github.com/pglombardo/PasswordPusher/issues/435

\app\frontend\js\pw_generator.js

	# Lines 9-30 change default generator constructor values for: titlecased, consonants, vowels, maxSyllableLength, minSyllableLength
    constructor() {
        this.config = {
            hasNumbers: true,
            titlecased: false,
            use_separators: true,
            consonants: 'bcDdFfGgHhKkLMmNnPpRrsTtVvZz',
            vowels: 'AaEeioUuYy',
            separators: '-_=',
            maxSyllableLength: 5,
            minSyllableLength: 3,
            syllablesCount: 3
        }

        this.config_defaults = {
            hasNumbers: true,
            titlecased: false,
            use_separators: true,
            consonants: 'bcDdFfGgHhKkLMmNnPpRrsTtVvZz',
            vowels: 'AaEeioUuYy',
            separators: '-_=',
            maxSyllableLength: 5,
            minSyllableLength: 3,
            syllablesCount: 3,
        };
    }




############ Height of Password entry field ############

\app\views\passwords\new.html.erb

	# Line 10 (change '8' to '3')
                                            rows: 3,




############ Password View Page WARNING ############

\app\views\passwords\show.html.erb

	# Line 6 (added above 'Please obtain and securely store this password elsewhere, ideally in a password manager.')
          <p class="" style="color: var(--bs-orange);"><strong><%=_('WARNING: <em>Refreshing this page will consume a view!') %></em></strong></p>




############ Footer copyright year, logo, site navigation (add HowTo, remove others) ############

\app\views\shared\_footer.html.erb

	# Line 5 
	  <p class="col-md-5 mb-0 text-muted">&copy; <%= Time.current.year %> Market Scan Information Systems</p>

	# Line 12 change alt="Market Scan Password Pusher Logo"
            <img src="<%= asset_pack_path('media/img/logo-transparent-sm-bare.png') %>" alt="<%= _('Market Scan Password Pusher Logo') %>" style='height: 40px;' />

	# Line 16 change alt="Market Scan Password Pusher Logo"
            <img src="<%= Settings.brand.light_logo %>" alt="<%= _('Market Scan Password Pusher Logo') %>" style='height: 40px;' />

	# Line 21 move to line 26 (if statement to hide footer links) and ADD Line 24 (Link to How To page)
        <ul class="nav col-md-5 justify-content-end">
          <li class="nav-item"><%= link_to _('Front Page'), root_path, class: 'nav-link px-2 text-muted' %></li>
		  <li class="nav-item"><%= link_to _('How To'), page_path('howto'), class: 'nav-link px-2 text-muted' %></li>
          
		  <% if Settings.brand && Settings.brand.show_footer_menu %>
			  <li class="nav-item dropdown">

	# Line 50 move to line 49 Fixes statement close to the correct element level caused by moving start of statement
			  </li>
		  <% end %>
        </ul>
    </footer>




############ ADDED FILE(S) ############

	# This file `_MS_BrandingChanges.md` located in the root
	
	# HowTo page
	\app\views\pages\howto.html.erb




############ ENVIRONMENT / CONFIG VARIABLES ############

https://dashboard.heroku.com/apps/msispwpush/settings
	Config Vars --> click [Reveal Config Vars] button
Config Vars
BUNDLE_WITHOUT	development:test:private
CRYPT_KEY	<hidden>
CRYPT_SALT	<hidden>
DATABASE_URL	postgres://zspqeacvctrezv:b5fa4c883928f0940d86118471b8fdb30f09a54971c6b41b61cb3935181f5a2d@ec2-34-233-105-94.compute-1.amazonaws.com:5432/ddi97sd0p8rs07
DELETABLE_PASSWORDS_DEFAULT	true
DELETABLE_PASSWORDS_ENABLED	true
EXPIRE_AFTER_DAYS_DEFAULT	7
EXPIRE_AFTER_DAYS_MAX	14
EXPIRE_AFTER_DAYS_MIN	1
EXPIRE_AFTER_VIEWS_DEFAULT	5
EXPIRE_AFTER_VIEWS_MAX	10
EXPIRE_AFTER_VIEWS_MIN	1
LANG	en_US.UTF-8
PAPERTRAIL_API_TOKEN	wo6siZp6tlRPsI6q6Eh
PAYLOAD_INITIAL_TEXT	Enter the Password to be Shared
PWP__ALLOW_ANONYMOUS	true
PWP__BRAND__SHOW_FOOTER_MENU	false
PWP__BRAND__TAGLINE	secure.marketscan.com - Send a Password, Securely.
PWP__BRAND__TITLE	Market Scan Password Pusher
PWP__DISABLE_SIGNUPS	false
PWP__ENABLE_LOGINS	true
PWP__HOST_DOMAIN	secure.marketscan.com
PWP__HOST_PROTOCOL	http
PWP__LOG_TO_STDOUT	true
PWP__MAIL__MAILER_SENDER	"Secure PW" <securePW@marketscan.com>
PWP__MAIL__OPEN_TIMEOUT	10
PWP__MAIL__RAISE_DELIVERY_ERRORS	true
PWP__MAIL__READ_TIMEOUT	10
PWP__MAIL__SMTP_ADDRESS	marketscan-com.mail.protection.outlook.com
PWP__MAIL__SMTP_PORT	25
PWP__MAIL__SMTP_STARTTLS	false
RACK_ENV	production
RAILS_ENV	production
RAILS_LOG_TO_STDOUT	enabled
RAILS_SERVE_STATIC_FILES	enabled
RETRIEVAL_STEP_DEFAULT	true
SECRET_KEY_BASE	<hidden>
SLACK_CLIENT_ID	<see below>
WEB_CONCURRENCY	3




############ SLACK_CLIENT_ID for Bots ############
	## TODO
	##   As of 10/24/2022 I am getting this message in the logs at https://my.papertrailapp.com/systems/msispwpush/events
	##   WARN -- : Can't verify CSRF token authenticity.

msispwpush
	SLACK_CLIENT_ID	358006997714.2511874001831

securepw
	SLACK_CLIENT_ID	358006997714.4253371584919
