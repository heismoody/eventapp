// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get language => 'Language';

  @override
  String get languageSheetTitle => 'Choose language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get genericError => 'Something went wrong. Try again.';

  @override
  String get couldNotOpenPage => 'Could not open the page';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navScan => 'Scan';

  @override
  String get navGuests => 'Guests';

  @override
  String get navContributions => 'Contributions';

  @override
  String get navTeam => 'Team';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeSlide1Title =>
      'Every guest. Every moment. Perfectly managed.';

  @override
  String get welcomeSlide1Body =>
      'Digital invitation cards, check-in at the door and contributions, all in one place.';

  @override
  String get welcomeSlide2Title => 'Celebrate with confidence';

  @override
  String get welcomeSlide2Body =>
      'Scan guests at the door, track check-ins and stay in control.';

  @override
  String get planEventWithCardly => 'Plan an event with Cardly';

  @override
  String get signIn => 'Sign in';

  @override
  String get invitedNote =>
      'Invited to an event? Your card comes by SMS. You don\'t need an account.';

  @override
  String get closeSignIn => 'Close sign in';

  @override
  String get newToCardly => 'New to Cardly?';

  @override
  String get planAnEvent => 'Plan an event';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle =>
      'Use the email or phone number Cardly set up for you.';

  @override
  String get emailOrPhone => 'Email or phone number';

  @override
  String get emailOrPhoneHint => 'you@example.com or 0712 345 678';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get advanced => 'Advanced';

  @override
  String get hideServerUrl => 'Hide server URL';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signInButton => 'Sign In';

  @override
  String get loginMissingFields =>
      'Enter your email or phone number, and your password.';

  @override
  String get loginCheckServerUrl => 'Check the server URL under Advanced.';

  @override
  String get loginUnexpected => 'Unexpected response from the server.';

  @override
  String get loginUnreachable =>
      'Can\'t reach the server. Check your internet connection.';

  @override
  String get loginBadCertificate =>
      'The server\'s security certificate isn\'t valid.';

  @override
  String get loginWrongPassword =>
      'That password doesn\'t match this email or phone number. Try again, or tap Forgot password.';

  @override
  String get loginNotAllowed =>
      'This account isn\'t allowed to use the Cardly app.';

  @override
  String get loginNotFound => 'Login service not found on this server.';

  @override
  String get serverProblem =>
      'The server had a problem. Please try again shortly.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get enterCodeTitle => 'Enter code';

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get enterIdentifier => 'Enter your email or phone number.';

  @override
  String get newCodeSent => 'New code sent.';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get passwordsDontMatch => 'The two passwords don\'t match.';

  @override
  String get passwordChangedSignedIn => 'Password changed. You are signed in.';

  @override
  String get forgotLead =>
      'Enter the email or phone number on your account. We\'ll send you a 6-digit code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get sending => 'Sending...';

  @override
  String codeSentLead(String destination) {
    return 'If $destination is on a Cardly account, we\'ve sent it a 6-digit code. It works for 10 minutes.';
  }

  @override
  String resendIn(String time) {
    return 'Didn\'t get it? Send again in $time';
  }

  @override
  String get sendCodeAgain => 'Send the code again';

  @override
  String get changeNumber => 'Change number';

  @override
  String get changeEmail => 'Change email';

  @override
  String get continueButton => 'Continue';

  @override
  String get checking => 'Checking...';

  @override
  String chooseNewPasswordFor(String name) {
    return 'Choose a new password for $name.';
  }

  @override
  String get chooseNewPassword => 'Choose a new password.';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get passwordHelper => 'At least 8 characters.';

  @override
  String get typeItAgain => 'Type it again';

  @override
  String get saveAndSignIn => 'Save and sign in';

  @override
  String get saving => 'Saving...';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get lostAccessTitle => 'No longer have that number or email?';

  @override
  String lostAccessBody(String number) {
    return 'WhatsApp us on $number and we\'ll help you back in.';
  }

  @override
  String get openWhatsApp => 'Open WhatsApp';

  @override
  String whatsAppUsOn(String number) {
    return 'WhatsApp us on $number.';
  }

  @override
  String get planYourEvent => 'Plan your event';

  @override
  String stepOfTotal(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepEventHeading => 'What are you planning?';

  @override
  String get stepYouHeading => 'How can we reach you?';

  @override
  String get stepReviewHeading => 'Check and send';

  @override
  String get edit => 'Edit';

  @override
  String get yourEvent => 'Your event';

  @override
  String get guests => 'Guests';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get noEmail => 'No email';

  @override
  String get eventLabel => 'Event';

  @override
  String get dateOfEvent => 'Date of the event';

  @override
  String get fillHighlighted => 'Fill in the highlighted parts.';

  @override
  String get aboutYou => 'About you';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get enterFirstName => 'Enter your first name';

  @override
  String get enterLastName => 'Enter your last name';

  @override
  String get phone => 'Phone';

  @override
  String get enterValidPhone => 'Enter a valid 9-digit number';

  @override
  String get phoneContactHint => 'We\'ll call or WhatsApp this number.';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get emailCopyHelper => 'We\'ll email you a copy of your request.';

  @override
  String get emailInvalid => 'This email doesn\'t look right';

  @override
  String get typeOfEvent => 'Type of event';

  @override
  String get chooseEventType => 'Choose the type of event';

  @override
  String get eventTypeWedding => 'Wedding';

  @override
  String get eventTypeSendOff => 'Send-off';

  @override
  String get eventTypeKitchenParty => 'Kitchen party';

  @override
  String get eventTypeBirthday => 'Birthday';

  @override
  String get eventTypeCorporate => 'Corporate';

  @override
  String get eventTypeOther => 'Something else';

  @override
  String get venue => 'Venue';

  @override
  String get venueHint => 'Hall, hotel or town';

  @override
  String get enterVenue => 'Enter the venue';

  @override
  String get chooseDateOrNotSure => 'Choose a date, or tick “Not sure”';

  @override
  String get notSureOfDate => 'Not sure of the date yet';

  @override
  String get howManyGuests => 'How many guests?';

  @override
  String get chooseGuestRange => 'Choose roughly how many guests';

  @override
  String get guestsUnder100 => 'Under 100';

  @override
  String get anythingElse => 'Anything else? (optional)';

  @override
  String get sendRequest => 'Send request';

  @override
  String get requestDisclaimer =>
      'Free, no commitment. We only use your details to contact you about this event.';

  @override
  String get date => 'Date';

  @override
  String get notSureYet => 'Not sure yet';

  @override
  String get requestUnreachable =>
      'Can\'t reach Cardly. Check your internet connection and try again.';

  @override
  String get requestCheckFields => 'Check the highlighted fields.';

  @override
  String get requestTooMany =>
      'Too many requests right now. Please try again in an hour.';

  @override
  String get requestFailed =>
      'We couldn\'t send your request. Please try again.';

  @override
  String couldntOpenCallUs(String number) {
    return 'Couldn\'t open that. Call us on $number.';
  }

  @override
  String get requestWithUs => 'Your request is with us.';

  @override
  String thanksRequestWithUs(String name) {
    return 'Thanks, $name. Your request is with us.';
  }

  @override
  String callYouOn(String phone) {
    return 'We\'ll call you on $phone within one working day.';
  }

  @override
  String get callYouSoon => 'We\'ll call you within one working day.';

  @override
  String emailedCopyTo(String email) {
    return 'We\'ve also emailed a copy to $email.';
  }

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get nextStep1 =>
      'We call to agree on the cards, the guest list and the price.';

  @override
  String get nextStep2 =>
      'We set up your event and send you an SMS and email to choose a password.';

  @override
  String get nextStep3 => 'Sign in here and your event is ready.';

  @override
  String get cantWait => 'Can\'t wait? Reach us now.';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get callUs => 'Call us';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get syncNow => 'Sync now';

  @override
  String get activeEvent => 'Active event';

  @override
  String get noEventSelected => 'No event selected';

  @override
  String get syncCheckIns => 'Sync check-ins';

  @override
  String waitingToSync(int count) {
    return '$count waiting to sync';
  }

  @override
  String get allSynced => 'All synced';

  @override
  String get serverConnection => 'Server connection';

  @override
  String get serverConnectionSubtitle => 'Manage API server URL';

  @override
  String get encryptionKey => 'Encryption key';

  @override
  String get encryptionKeySubtitle => 'QR code decryption key';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Common questions about Cardly';

  @override
  String get terms => 'Terms of service';

  @override
  String get termsSubtitle => 'The rules for using Cardly';

  @override
  String get userPolicy => 'User policy';

  @override
  String get userPolicySubtitle => 'How your data is handled';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logOutBody => 'You will need to sign in again to use the app.';

  @override
  String get serverUrlSaved => 'Server URL saved';

  @override
  String get keyMustBe64 => 'Key must be 64 hex characters';

  @override
  String get eventKeySaved => 'Event key saved';

  @override
  String get keyRedownloaded => 'Key re-downloaded';

  @override
  String get keyDownloadFailed => 'Failed to download key';

  @override
  String syncedSomeWaiting(int synced, int waiting) {
    return 'Synced $synced. $waiting still waiting, check the network.';
  }

  @override
  String get everythingSynced => 'Everything is synced';

  @override
  String syncedCheckIns(int count) {
    return 'Synced $count check-ins';
  }

  @override
  String get selectEventFirst => 'Select an event first';

  @override
  String get pasteKeyHelp =>
      'Paste the 64-character key for decrypting guest QR codes.';

  @override
  String get eventKey => 'Event key';

  @override
  String get eventKeyHint => '64-character hex key';

  @override
  String get saveKey => 'Save key';

  @override
  String get redownload => 'Re-download';

  @override
  String get dashCheckedIn => 'Checked in';

  @override
  String dashCheckedInPeople(int count) {
    return 'Checked in · $count people';
  }

  @override
  String dashQueued(String label) {
    return '$label · queued';
  }

  @override
  String get guestFallback => 'Guest';

  @override
  String get dashContributed => 'Contributed';

  @override
  String get dashAddedAsGuest => 'Added as guest';

  @override
  String get dashSummary => 'Summary';

  @override
  String get dashAllSettled => 'All settled';

  @override
  String get dashUnpaid => 'unpaid';

  @override
  String get dashRecentActivity => 'Recent activity';

  @override
  String get dashTrends => 'Trends';

  @override
  String dashOwesBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests still owe a balance',
      one: '1 guest still owes a balance',
    );
    return '$_temp0';
  }

  @override
  String get dashViewGuests => 'View guests';

  @override
  String get dashManageTeam => 'Manage team';

  @override
  String get dashViewReport => 'View report';

  @override
  String dashSyncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count check-ins waiting to sync',
      one: '1 check-in waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String dashOfflineQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offline · $count check-ins queued',
      one: 'Offline · 1 check-in queued',
    );
    return '$_temp0';
  }

  @override
  String get dashPeople => 'People';

  @override
  String get dashEntered => 'Entered';

  @override
  String get dashPending => 'Pending';

  @override
  String get dashRate => 'Rate';

  @override
  String get dashDays => 'days';

  @override
  String get dashHours => 'hrs';

  @override
  String get dashMinutes => 'mins';

  @override
  String get dashSeconds => 'secs';

  @override
  String get dashNoGuestsAdded => 'No guests added yet';

  @override
  String get dashAddGuests => 'Add guests';

  @override
  String get dashNoTeam => 'No team members yet';

  @override
  String get dashAddTeamMember => 'Add team member';

  @override
  String get dashNoContributions => 'No contributions recorded yet';

  @override
  String get dashSetUpContributions => 'Set up contributions';

  @override
  String get dashNoCategory => 'No category';

  @override
  String get dashContributionsCollected => 'Contributions collected';

  @override
  String dashCollectedAmount(String amount) {
    return 'TZS $amount collected';
  }

  @override
  String dashTargetAmount(String amount) {
    return 'Target: TZS $amount';
  }

  @override
  String get dashByCategory => 'By category';

  @override
  String dashGuestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get dashNoGuestsYet => 'No guests yet';

  @override
  String get dashImportGuests =>
      'Import guests to start tracking contributions';

  @override
  String get dashNoActivity => 'No recent activity yet';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get dashSelectEvent => 'Select an event to view your dashboard';

  @override
  String get tryAgain => 'Try again';

  @override
  String get guestNotFound => 'Guest not found';

  @override
  String get checkInFailed => 'Check-in failed. Try again.';

  @override
  String get phoneCopied => 'Phone number copied';

  @override
  String get editGuest => 'Edit guest';

  @override
  String get checkInGuest => 'Check in guest';

  @override
  String checkInProgress(int entered, int admits) {
    return 'Check in · $entered of $admits entered';
  }

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabPayment => 'Payment';

  @override
  String get guestProfile => 'Guest profile';

  @override
  String get amountPaid => 'Amount paid';

  @override
  String get balance => 'Balance';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get contact => 'Contact';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get copyNumber => 'Copy number';

  @override
  String get checkInSection => 'Check-in';

  @override
  String get status => 'Status';

  @override
  String get notCheckedIn => 'Not checked in';

  @override
  String get checkedInAt => 'Checked in at';

  @override
  String get contribution => 'Contribution';

  @override
  String get category => 'Category';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get targetAmount => 'Target amount';

  @override
  String get qrCard => 'QR card';

  @override
  String get qrCardMessage => 'QR card message';

  @override
  String get sent => 'Sent';

  @override
  String get notSentYet => 'Not sent yet';

  @override
  String get sentAt => 'Sent at';

  @override
  String get paymentSummary => 'Payment summary';

  @override
  String get balanceRemaining => 'Balance remaining';

  @override
  String percentOfTargetPaid(int percent) {
    return '$percent% of target paid';
  }

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get statusFullyPaid => 'Fully paid';

  @override
  String get statusPartiallyPaid => 'Partially paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get guestUpdated => 'Guest updated';

  @override
  String get updateGuestFailed => 'Failed to update guest';

  @override
  String alsoOnCard(String phone, String name) {
    return '$phone is also on $name\'s card';
  }

  @override
  String alsoGuestNotMerged(String phone, String name) {
    return '$phone is also the guest $name, who has entries or payments, so they weren\'t merged';
  }

  @override
  String mergeTitle(String name) {
    return 'Merge $name?';
  }

  @override
  String mergeBody(String phone, String name) {
    return '$phone is already $name, a guest with their own card, so they would get two invitations. Merge them into this card as a companion?';
  }

  @override
  String get keepBoth => 'Keep both';

  @override
  String get merge => 'Merge';

  @override
  String get companions => 'Companions';

  @override
  String get companionsHint =>
      'Others sharing this card. Anyone with a phone gets the same invitation.';

  @override
  String get optional => 'Optional';

  @override
  String get removeCompanion => 'Remove companion';

  @override
  String get addCompanion => 'Add companion';

  @override
  String get contributionCategory => 'Contribution category';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get peopleOnCard => 'People on this card';

  @override
  String alreadyEntered(int count) {
    return '$count already entered';
  }

  @override
  String get peopleOnCardHint => 'How many people this card lets in';

  @override
  String get amountPaidTzs => 'Amount paid (TZS)';

  @override
  String get pledgeTzs => 'Pledge (TZS, optional)';

  @override
  String get pledgeHelper => 'What this guest has promised to contribute';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get categoryOptional => 'Category (optional)';

  @override
  String get selectedCategory => 'Selected category';

  @override
  String get enterHowManyPeople => 'Enter how many people';

  @override
  String fromOneTo(int max) {
    return 'From 1 to $max';
  }

  @override
  String cantBeFewer(int count) {
    return '$count already entered, so it can\'t be fewer';
  }

  @override
  String admitPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admit $count people',
      one: 'Admit 1 person',
    );
    return '$_temp0';
  }

  @override
  String get continueScanning => 'Continue scanning';

  @override
  String get cardUnknownNote =>
      'This card isn\'t in the phone\'s guest list yet, so its places are unknown. Admitting one person. Refresh the guest list when the network is back.';

  @override
  String get manualCheckInNote =>
      'Confirm this is the person at the door. This is recorded as a manual check-in.';

  @override
  String get cardFullyUsed => 'Card fully used';

  @override
  String get notAdmitted => 'Not admitted';

  @override
  String get admitted => 'Admitted';

  @override
  String get savedOnPhoneNote =>
      'Saved on this phone. It will sync automatically when the network allows.';

  @override
  String overBy(int count) {
    return 'Over by $count';
  }

  @override
  String get noPlacesLeft => 'No places left';

  @override
  String placesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places left',
      one: '1 place left',
    );
    return '$_temp0';
  }

  @override
  String enteredOf(int entered, int admits) {
    return '$entered of $admits';
  }

  @override
  String get enteredWord => 'entered';

  @override
  String get firstEntry => 'First entry';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get waitingToSyncShort => 'waiting to sync';

  @override
  String get peopleEnteringNow => 'People entering now';

  @override
  String get oneFewer => 'One fewer';

  @override
  String get oneMore => 'One more';

  @override
  String get noCategoryAssigned => 'No category assigned';

  @override
  String get invalidQr => 'Invalid QR code';

  @override
  String get invalidQrBody =>
      'Could not decrypt this code. Check your event key in Settings.';

  @override
  String get addContribution => 'Add contribution';

  @override
  String addContributionSelected(int count) {
    return 'Add contribution ($count selected)';
  }

  @override
  String get tabStats => 'Stats';

  @override
  String get tabList => 'List';

  @override
  String get searchByName => 'Search by name';

  @override
  String get collected => 'Collected';

  @override
  String get expected => 'Expected';

  @override
  String get partial => 'Partial';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get byCategoryTitle => 'By category';

  @override
  String get loadCategoryDataFailed => 'Failed to load category data';

  @override
  String get noContributionsCollected => 'No contributions collected yet';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get overTime => 'Over time';

  @override
  String get loadContributionsFailed => 'Failed to load contributions';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnpaid => 'Unpaid';

  @override
  String get filterPartial => 'Partial';

  @override
  String get filterFull => 'Full';

  @override
  String get noContributionsFound => 'No contributions found';

  @override
  String get noContributionsFoundHint =>
      'Try a different filter, or set a pledge on a guest to track it here.';

  @override
  String get contributionCategories => 'Contribution categories';

  @override
  String get noCategoriesTapPlus =>
      'No categories yet.\nTap + to add Single, Double, Family and so on.';

  @override
  String peoplePerCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people per card',
      one: '1 person per card',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteCategoryFailed => 'Failed to delete category';

  @override
  String get noGuestsFound => 'No guests found';

  @override
  String get clearAll => 'Clear all';

  @override
  String get selectAll => 'Select all';

  @override
  String get pickAtLeastOneGuest => 'Pick at least one guest';

  @override
  String get enterPledgeOrPaid => 'Enter a pledge, an amount paid, or both';

  @override
  String updatedGuests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count guests',
      one: 'Updated 1 guest',
    );
    return '$_temp0';
  }

  @override
  String updatedSomeFailed(int succeeded, int failed) {
    return 'Updated $succeeded, failed for $failed';
  }

  @override
  String get updateContributionFailed => 'Failed to update contribution';

  @override
  String get searchGuestByName => 'Search guest by name';

  @override
  String get loadGuestsFailed => 'Could not load guests';

  @override
  String get pledgePerGuest => 'Pledge per guest (TZS)';

  @override
  String get pledgePerGuestHelper => 'What they committed to give';

  @override
  String get paidPerGuest => 'Paid per guest (TZS)';

  @override
  String get paidPerGuestHelper => 'Money received now';

  @override
  String saveForGuests(int count) {
    return 'Save for $count guests';
  }

  @override
  String deleteCategoryTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryBody =>
      'Guests in this category will be left without a category. Their pledges and payments are not affected.';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get loadCategoriesFailed => 'Could not load categories.';

  @override
  String get noCategoriesUsePlus =>
      'No categories yet. Use the + button to create one.';

  @override
  String get updateExistingCardsTitle => 'Update existing cards?';

  @override
  String updateExistingCardsBody(int from, int to) {
    return 'Cards of this type that still admit $from can change to $to too. Cards set to another number by hand keep theirs.';
  }

  @override
  String get onlyNewCards => 'Only new cards';

  @override
  String get updateCards => 'Update cards';

  @override
  String get enterCategoryName => 'Enter a category name';

  @override
  String get categorySaved => 'Category saved';

  @override
  String categoryUpdatedCards(int count, int people) {
    return 'Category updated · $count cards now admit $people';
  }

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get saveCategoryFailed => 'Failed to save category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get peoplePerCardLabel => 'People per card';

  @override
  String get peoplePerCardHelper =>
      'How many people one card of this type lets in, for example 2 for a couple. Each card can still be changed.';

  @override
  String get saveCategory => 'Save category';

  @override
  String get createMemberFailed => 'Failed to create member account';

  @override
  String get loadTeamFailed => 'Failed to load team';

  @override
  String get nameAndEmailRequired => 'Name and email are required';

  @override
  String get passwordMin6 => 'Password must be at least 6 characters';

  @override
  String get memberCreated => 'Member account created';

  @override
  String get addKamatiMember => 'Add kamati member';

  @override
  String get addKamatiMemberLead =>
      'Create an account for a committee member to help monitor your event.';

  @override
  String get fullName => 'Full name';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get creating => 'Creating…';

  @override
  String get createMember => 'Create member';

  @override
  String get members => 'Members';

  @override
  String addedOn(String date) {
    return 'Added $date';
  }

  @override
  String get noKamatiMembers => 'No kamati members yet';

  @override
  String get noKamatiMembersHint =>
      'Tap + to add committee members who can help scan guests and monitor your event.';

  @override
  String get scanCard => 'Scan card';

  @override
  String get pickEventToCheckIn => 'Pick an event to start checking guests in.';

  @override
  String get loadGuestListFailed => 'Couldn\'t load the guest list';

  @override
  String get pullToRetry => 'Pull down to try again.';

  @override
  String get noGuestsOnEvent => 'No guests on this event yet';

  @override
  String get noGuestListOnPhone =>
      'This phone doesn\'t have the guest list yet';

  @override
  String get noGuestsOnEventHint =>
      'Guests added in the portal or on the Guests tab show up here.';

  @override
  String get noGuestListOnPhoneHint =>
      'Connect to the internet once to download it. Scanning still works offline.';

  @override
  String get tabArrived => 'Arrived';

  @override
  String get tabStillToCome => 'Still to come';

  @override
  String get peopleIn => 'People in';

  @override
  String get cardsUsed => 'Cards used';

  @override
  String get partlyIn => 'Partly in';

  @override
  String waitingSyncPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people admitted on this phone are waiting to sync',
      one: '1 person admitted on this phone is waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get byCardType => 'By card type';

  @override
  String get everyoneIsIn => 'Everyone is in';

  @override
  String categoryProgress(int toCome, int arrived, int cards) {
    return '$toCome still to come, $arrived of $cards cards used';
  }

  @override
  String get filterArrived => 'Filter guests who arrived';

  @override
  String get filterToCome => 'Filter guests still to come';

  @override
  String get allCardTypes => 'All card types';

  @override
  String cardTypeCards(String type) {
    return '$type cards';
  }

  @override
  String get showAllCardTypes => 'Show all card types';

  @override
  String get searchByNameOrPhone => 'Search by name or phone';

  @override
  String get filterByCardType => 'Filter by card type';

  @override
  String get cardType => 'Card type';

  @override
  String typeAtTime(String type, String time) {
    return '$type, $time';
  }

  @override
  String typePartlyIn(String type, int entered, int admits) {
    return '$type, $entered of $admits in';
  }

  @override
  String get waitingSyncTooltip => 'Admitted on this phone, waiting to sync';

  @override
  String placesLeftShort(int count) {
    return '$count left';
  }

  @override
  String enteredShort(int entered, int admits) {
    return '$entered/$admits in';
  }

  @override
  String get noSearchMatch => 'No guests match your search';

  @override
  String get noSearchMatchHint => 'Check the spelling or clear it.';

  @override
  String get noOneInYet => 'No one is in yet';

  @override
  String noOneOfTypeInYet(String type) {
    return 'No one with a $type card is in yet';
  }

  @override
  String get tapScanWhenArrives =>
      'Tap Scan card when the first guest arrives.';

  @override
  String everyTypeIn(String type) {
    return 'Every $type card is in';
  }

  @override
  String get noPlacesToFill => 'No places left to fill.';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get noCardType => 'No card type';

  @override
  String get backToDoor => 'Back to the door overview';

  @override
  String get keepsScanning => 'Keeps scanning after each guest';

  @override
  String peopleInOf(int peopleIn, int expected) {
    return '$peopleIn of $expected people in';
  }

  @override
  String get flashlightOff => 'Turn off flashlight';

  @override
  String get flashlightOn => 'Turn on flashlight';

  @override
  String get checkingCard => 'Checking card…';

  @override
  String get alignQr => 'Align the QR code inside the frame. Pinch to zoom.';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoom => 'Zoom';

  @override
  String get alreadyCheckedIn => 'Already checked in';

  @override
  String get serverRefusedCheckIn => 'The server refused this check-in';

  @override
  String get addGuestManually => 'Add guest manually';

  @override
  String get importFromContacts => 'Import from contacts';

  @override
  String get offlineLocalGuests =>
      'Offline · showing locally scanned guests only';

  @override
  String get pending => 'Pending';

  @override
  String get noGuestsFoundHint =>
      'Try a different filter or tap + to add a guest.';

  @override
  String get loadGuestsFailedTitle => 'Failed to load guests';

  @override
  String get guestAdded => 'Guest added';

  @override
  String get addGuestFailed => 'Failed to add guest. Please try again.';

  @override
  String get addGuest => 'Add guest';

  @override
  String get addGuestLead =>
      'Enter their details by hand instead of picking from contacts.';

  @override
  String leaveEmptyForDefault(int count) {
    return 'Leave empty for the category\'s $count';
  }

  @override
  String get contactsPermissionNeeded =>
      'Contacts permission is required to import guests.';

  @override
  String get loadContactsFailed => 'Failed to load contacts.';

  @override
  String get importNeedsInternet => 'Import requires an internet connection';

  @override
  String importResult(int inserted, int skipped) {
    return '$inserted added, $skipped skipped';
  }

  @override
  String get importFailed => 'Import failed. Please try again.';

  @override
  String get importContacts => 'Import contacts';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String contactsSelected(int count, int selected) {
    return '$count contacts · $selected selected';
  }

  @override
  String get noContactsWithPhones => 'No contacts with phone numbers found';

  @override
  String get importing => 'Importing…';

  @override
  String importCount(int count) {
    return 'Import ($count)';
  }

  @override
  String get guestPhoneExists =>
      'A guest with this phone number already exists';

  @override
  String get trackMyRequest => 'Track my request';

  @override
  String requestSentTo(String name) {
    return 'Request sent, $name';
  }

  @override
  String get requestSpokenTitle => 'We\'ve spoken with you';

  @override
  String get requestSettingUpLead =>
      'We\'re setting up your event. We\'ll text you when it\'s ready.';

  @override
  String get requestReadyTitle => 'Your event is ready';

  @override
  String requestReadyLead(String phone) {
    return 'Choose a password to open it. You\'ll sign in with $phone.';
  }

  @override
  String get requestClosedTitle => 'Request closed';

  @override
  String get requestClosedLead =>
      'This request won\'t go ahead. If your plans change, send us a new one.';

  @override
  String get stepReceived => 'We received it';

  @override
  String get stepWeCall => 'We call you';

  @override
  String get stepWeCalled => 'We called you';

  @override
  String get stepCallHint => 'To agree on the details and price';

  @override
  String get stepSettingUp => 'Setting up your event';

  @override
  String get stepSetUp => 'Your event is set up';

  @override
  String get stepSetUpHint => 'Then you choose your password';

  @override
  String get choosePasswordButton => 'Choose your password';

  @override
  String get sendNewRequest => 'Send a new request';

  @override
  String get checkingForUpdates => 'Checking for updates...';

  @override
  String statusUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get statusRefreshFailed =>
      'Couldn\'t check for updates. This is the last status we had.';

  @override
  String get savePassword => 'Save password';

  @override
  String get passwordSavedSignIn =>
      'Password saved. Tap Sign In to open your event.';

  @override
  String get updateReadyTitle => 'Update downloaded';

  @override
  String get updateReadyBody => 'Restart Cardly to finish updating.';

  @override
  String get updateRestart => 'Restart';

  @override
  String get selectEventTitle => 'Select event';

  @override
  String get eventsLoadFailedTitle => 'Couldn\'t load your events';

  @override
  String get eventsLoadFailedBody =>
      'Check your internet connection and try again. If it keeps happening, sign out and sign in again.';

  @override
  String get noEventsTitle => 'No events yet';

  @override
  String get noEventsBody =>
      'Events you\'re part of show up here. Pull down to check again.';

  @override
  String get eventKeyMissing => 'Key missing';

  @override
  String get noVenue => 'No venue';

  @override
  String get eventKeySavedChip => 'Key saved';

  @override
  String get whereSendCodeTitle => 'Where should we send your code?';

  @override
  String whereSendCodeLead(String name) {
    return 'We\'ll send a 6-digit code to make sure it\'s really you, $name.';
  }

  @override
  String get viaTextMessage => 'Text message';

  @override
  String viaTextTo(String hint) {
    return 'To your phone ending $hint';
  }

  @override
  String get viaEmail => 'Email';

  @override
  String viaEmailTo(String hint) {
    return 'To $hint';
  }

  @override
  String get cantUseEither => 'Can\'t use either?';

  @override
  String get whatsAppUsLink => 'WhatsApp us';

  @override
  String codeTextedTo(String hint) {
    return 'We texted a 6-digit code to your phone ending $hint.';
  }

  @override
  String codeEmailedTo(String hint) {
    return 'We emailed a 6-digit code to $hint.';
  }

  @override
  String get noSmsYet => 'No SMS yet?';

  @override
  String get noEmailYet => 'No email yet?';

  @override
  String sendToInstead(String hint) {
    return 'Send it to $hint instead';
  }

  @override
  String get eventNotReadyYet =>
      'Your event isn\'t ready yet. Pull down on the request page to check again, or WhatsApp us.';

  @override
  String get chooseCategoryTitle => 'Choose a category';

  @override
  String get chooseCategoryLead =>
      'It sets how many people a card admits. You can change that per guest.';

  @override
  String admitsPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Admits $count people',
      one: 'Admits 1 person',
    );
    return '$_temp0';
  }

  @override
  String get newCategoryButton => 'New category';

  @override
  String get tapToChoose => 'Tap to choose';

  @override
  String get importFromExcel => 'Import from Excel';

  @override
  String get excelImportLead =>
      'Use an Excel or CSV file laid out like this, one guest per row. Download the sample to start from it.';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get chooseAnotherFile => 'Choose another file';

  @override
  String readingFile(String file) {
    return 'Reading $file…';
  }

  @override
  String excelWillAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests will be added',
      one: '1 guest will be added',
      zero: 'No new guests to add',
    );
    return '$_temp0';
  }

  @override
  String excelMoreRows(int count) {
    return 'and $count more';
  }

  @override
  String get excelNewCategories => 'New categories';

  @override
  String excelDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already on the list',
      one: '1 already on the list',
    );
    return '$_temp0';
  }

  @override
  String get excelDuplicatesHint =>
      'Same phone number as a guest you have, or repeated in the file. These are skipped.';

  @override
  String excelProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows can\'t be imported',
      one: '1 row can\'t be imported',
    );
    return '$_temp0';
  }

  @override
  String get excelProblemsHint =>
      'Fix these in the file and import it again. Guests already added are skipped.';

  @override
  String excelRow(int row) {
    return 'Row $row';
  }

  @override
  String excelImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count guests',
      one: 'Import 1 guest',
    );
    return '$_temp0';
  }

  @override
  String excelImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests added',
      one: '1 guest added',
    );
    return '$_temp0';
  }

  @override
  String get excelReadFailed => 'Couldn\'t read that file. Please try again.';

  @override
  String get excelFileTooBig => 'That file is too big. The limit is 2 MB.';

  @override
  String get sampleSheet => 'Sample';

  @override
  String get downloadSampleSheet => 'Download a sample sheet';

  @override
  String get sampleSheetSaved =>
      'Sample saved. Fill it in, then choose it here.';

  @override
  String get sampleSheetFailed =>
      'Couldn\'t download the sample. Please try again.';

  @override
  String get setupLinkChecking => 'Checking your link...';

  @override
  String get setupLinkUsedTitle => 'This link has already been used';

  @override
  String get setupLinkUsedBody =>
      'Your password is set. Sign in with it. If you forgot it, tap Forgot password on the sign-in screen.';

  @override
  String get setupLinkExpiredTitle => 'This link has expired';

  @override
  String get setupLinkExpiredBody =>
      'Links work for 7 days. WhatsApp us and we\'ll send you a new one.';

  @override
  String get setupLinkInvalidTitle => 'This link doesn\'t work';

  @override
  String get setupLinkInvalidBody =>
      'Open the link from your SMS or email again, or WhatsApp us and we\'ll send a new one.';

  @override
  String get setupLinkCheckFailed =>
      'We couldn\'t check your link. Check your internet connection and try again.';

  @override
  String get goToSignIn => 'Go to sign in';

  @override
  String setupSavedWhileSignedIn(String signInWith) {
    return 'Password saved. Sign out, then sign in with $signInWith.';
  }

  @override
  String get updateAlreadyLatest => 'You have the latest version of Cardly.';

  @override
  String get updateCheckFailed =>
      'Couldn\'t check for updates. Check your internet connection and try again.';
}
