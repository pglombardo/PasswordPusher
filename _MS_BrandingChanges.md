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
	## Verify if this can be adjusted in config/settings for instance instead 
	##
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




############ Footer Slogan ############
\app\views\shared\_email_footer.html.erb
	# Line 4 change 'Your Friendly Neighborhood' to 'Market Scan Information Systems'
<%= _('Market Scan Information Systems') %>




############ Footer copyright, logo, number of columns, site navigation (add HowTo, remove others) ############
\app\views\shared\_footer.html.erb
	# Line 5 
      <p class="col-md-4 mb-0 text-muted">&copy; <%= Time.current.year %> Market Scan Information Systems</p>

	# Line 11 change alt="Market Scan Password Pusher Logo"
          <img src="<%= asset_pack_path('media/img/logo-transparent-sm-bare.png') %>" alt="Market Scan Password Pusher Logo" style='height: 40px;' />

	# Line 15 change col-md-5 to col-md-4
      <ul class="nav col-md-4 justify-content-end">

	# Lines 21-26 (MUST ADD link to "How To" page | also comment out other pages)
            <li class="dropdown-item"><%= link_to _('How To'), page_path('howto'), class: 'nav-link px-2 text-muted' %></li>
			<!-- <li class="dropdown-item"><%= link_to _('FAQ'), page_path('faq'), class: 'nav-link px-2 text-muted' %></li> -->
            <!-- <li class="dropdown-item"><%= link_to _('Tools'), page_path('tools'), class: 'nav-link px-2 text-muted' %></li> -->
            <!-- <li class="dropdown-item"><%= link_to _('Source Code'), 'https://github.com/pglombardo/PasswordPusher', class: 'nav-link px-2 text-muted', target: '_blank' %></li> -->
            <!-- <li class="dropdown-item"><%= link_to _('Docker Containers'), 'https://hub.docker.com/u/pglombardo', class: 'nav-link px-2 text-muted', target: '_blank' %></li> -->
            <li class="dropdown-item"><%= link_to _('Key Generator'), page_path('generate_key'), class: 'nav-link px-2 text-muted' %></li>




############ Header Logo & Slogan ############
\app\views\shared\_header.html.erb
	# Lines 8-14
        <img src="<%= asset_pack_path('media/img/logo-transparent-sm-bare.png') %>" alt="<%= _('Market Scan Password Pusher Logo') %>" style='height: 50px;' />
      </picture>
      </div>
      <div>
        <span class="fs-4 display-1"><%= _('Market Scan Password Pusher') %></span>
        <br/>
        <span class="fs-6 text-muted"><%= _('Powered by Peter Giacomo Lombardo's Password Pusher.') %></span>




############ ADDED FILE(S) ############
	# This file `_MS_BrandingChanges.md` located in the root
	
	# HowTo page
	\app\views\pages\howto.html.erb
