// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get languageName => 'Kiswahili';

  @override
  String get language => 'Lugha';

  @override
  String get languageSheetTitle => 'Chagua lugha';

  @override
  String get appearance => 'Mwonekano';

  @override
  String get themeSystem => 'Kama simu yako';

  @override
  String get themeLight => 'Mwanga';

  @override
  String get themeDark => 'Giza';

  @override
  String get back => 'Rudi';

  @override
  String get cancel => 'Ghairi';

  @override
  String get save => 'Hifadhi';

  @override
  String get done => 'Sawa';

  @override
  String get genericError => 'Kuna tatizo limetokea. Jaribu tena.';

  @override
  String get couldNotOpenPage => 'Imeshindwa kufungua ukurasa';

  @override
  String get navDashboard => 'Muhtasari';

  @override
  String get navScan => 'Skani';

  @override
  String get navGuests => 'Wageni';

  @override
  String get navContributions => 'Michango';

  @override
  String get navTeam => 'Timu';

  @override
  String get navSettings => 'Mipangilio';

  @override
  String get welcomeSlide1Title =>
      'Kila mgeni. Kila wakati. Vyote kwa mpangilio.';

  @override
  String get welcomeSlide1Body =>
      'Kadi za mwaliko za kidijitali, kupokea wageni mlangoni na michango, vyote sehemu moja.';

  @override
  String get welcomeSlide2Title => 'Sherehekea bila wasiwasi';

  @override
  String get welcomeSlide2Body =>
      'Skani wageni mlangoni, fuatilia waliofika na simamia kila kitu.';

  @override
  String get planEventWithCardly => 'Panga tukio na Cardly';

  @override
  String get signIn => 'Ingia';

  @override
  String get invitedNote =>
      'Umealikwa kwenye tukio? Kadi yako inakuja kwa SMS. Huhitaji akaunti.';

  @override
  String get closeSignIn => 'Funga sehemu ya kuingia';

  @override
  String get newToCardly => 'Hujawahi kutumia Cardly?';

  @override
  String get planAnEvent => 'Panga tukio';

  @override
  String get welcomeBack => 'Karibu tena';

  @override
  String get signInSubtitle =>
      'Tumia barua pepe au namba ya simu ambayo Cardly walikusajilia.';

  @override
  String get emailOrPhone => 'Barua pepe au namba ya simu';

  @override
  String get emailOrPhoneHint => 'wewe@mfano.com au 0712 345 678';

  @override
  String get password => 'Nenosiri';

  @override
  String get showPassword => 'Onyesha nenosiri';

  @override
  String get hidePassword => 'Ficha nenosiri';

  @override
  String get advanced => 'Zaidi';

  @override
  String get hideServerUrl => 'Ficha anwani ya seva';

  @override
  String get serverUrl => 'Anwani ya seva';

  @override
  String get forgotPasswordLink => 'Umesahau nenosiri?';

  @override
  String get signingIn => 'Inaingia...';

  @override
  String get signInButton => 'Ingia';

  @override
  String get loginMissingFields =>
      'Weka barua pepe au namba ya simu, na nenosiri lako.';

  @override
  String get loginCheckServerUrl => 'Angalia anwani ya seva kwenye Zaidi.';

  @override
  String get loginUnexpected => 'Seva imejibu kwa namna isiyotarajiwa.';

  @override
  String get loginUnreachable =>
      'Imeshindwa kufikia seva. Angalia intaneti yako.';

  @override
  String get loginBadCertificate => 'Cheti cha usalama cha seva si sahihi.';

  @override
  String get loginWrongPassword =>
      'Nenosiri hilo halilingani na barua pepe au namba hii. Jaribu tena, au gusa Umesahau nenosiri.';

  @override
  String get loginNotAllowed =>
      'Akaunti hii hairuhusiwi kutumia programu ya Cardly.';

  @override
  String get loginNotFound => 'Huduma ya kuingia haipatikani kwenye seva hii.';

  @override
  String get serverProblem =>
      'Seva imepata tatizo. Tafadhali jaribu tena baada ya muda mfupi.';

  @override
  String get loginFailed => 'Imeshindwa kuingia. Tafadhali jaribu tena.';

  @override
  String get forgotTitle => 'Umesahau nenosiri';

  @override
  String get enterCodeTitle => 'Weka msimbo';

  @override
  String get newPasswordTitle => 'Nenosiri jipya';

  @override
  String get enterIdentifier => 'Weka barua pepe au namba yako ya simu.';

  @override
  String get newCodeSent => 'Msimbo mpya umetumwa.';

  @override
  String get enterSixDigitCode => 'Weka msimbo wa tarakimu 6.';

  @override
  String get passwordTooShort => 'Tumia angalau herufi 8.';

  @override
  String get passwordsDontMatch => 'Manenosiri hayo mawili hayalingani.';

  @override
  String get passwordChangedSignedIn => 'Nenosiri limebadilishwa. Umeingia.';

  @override
  String get forgotLead =>
      'Weka barua pepe au namba ya simu iliyo kwenye akaunti yako. Tutakutumia msimbo wa tarakimu 6.';

  @override
  String get sendCode => 'Tuma msimbo';

  @override
  String get sending => 'Inatuma...';

  @override
  String codeSentLead(String destination) {
    return 'Kama $destination ipo kwenye akaunti ya Cardly, tumetuma msimbo wa tarakimu 6. Unafanya kazi kwa dakika 10.';
  }

  @override
  String resendIn(String time) {
    return 'Hujaupata? Tuma tena baada ya $time';
  }

  @override
  String get sendCodeAgain => 'Tuma msimbo tena';

  @override
  String get changeNumber => 'Badilisha namba';

  @override
  String get changeEmail => 'Badilisha barua pepe';

  @override
  String get continueButton => 'Endelea';

  @override
  String get checking => 'Inakagua...';

  @override
  String chooseNewPasswordFor(String name) {
    return 'Chagua nenosiri jipya la $name.';
  }

  @override
  String get chooseNewPassword => 'Chagua nenosiri jipya.';

  @override
  String get newPasswordLabel => 'Nenosiri jipya';

  @override
  String get passwordHelper => 'Angalau herufi 8.';

  @override
  String get typeItAgain => 'Liandike tena';

  @override
  String get saveAndSignIn => 'Hifadhi na uingie';

  @override
  String get saving => 'Inahifadhi...';

  @override
  String get sixDigitCode => 'Msimbo wa tarakimu 6';

  @override
  String get lostAccessTitle => 'Huna tena namba au barua pepe hiyo?';

  @override
  String lostAccessBody(String number) {
    return 'Tuandikie WhatsApp kwa $number na tutakusaidia kuingia tena.';
  }

  @override
  String get openWhatsApp => 'Fungua WhatsApp';

  @override
  String whatsAppUsOn(String number) {
    return 'Tuandikie WhatsApp kwa $number.';
  }

  @override
  String get planYourEvent => 'Panga tukio lako';

  @override
  String stepOfTotal(int current, int total) {
    return 'Hatua $current kati ya $total';
  }

  @override
  String get stepEventHeading => 'Unapanga nini?';

  @override
  String get stepYouHeading => 'Tukupate vipi?';

  @override
  String get stepReviewHeading => 'Hakiki na utume';

  @override
  String get edit => 'Badilisha';

  @override
  String get yourEvent => 'Tukio lako';

  @override
  String get guests => 'Wageni';

  @override
  String get name => 'Jina';

  @override
  String get email => 'Barua pepe';

  @override
  String get noEmail => 'Hakuna barua pepe';

  @override
  String get eventLabel => 'Tukio';

  @override
  String get dateOfEvent => 'Tarehe ya tukio';

  @override
  String get fillHighlighted => 'Jaza sehemu zilizowekewa alama.';

  @override
  String get aboutYou => 'Kuhusu wewe';

  @override
  String get firstName => 'Jina la kwanza';

  @override
  String get lastName => 'Jina la mwisho';

  @override
  String get enterFirstName => 'Weka jina lako la kwanza';

  @override
  String get enterLastName => 'Weka jina lako la mwisho';

  @override
  String get phone => 'Simu';

  @override
  String get enterValidPhone => 'Weka namba sahihi ya tarakimu 9';

  @override
  String get phoneContactHint =>
      'Tutakupigia au kukuandikia WhatsApp kwa namba hii.';

  @override
  String get emailOptional => 'Barua pepe (si lazima)';

  @override
  String get emailCopyHelper =>
      'Tutakutumia nakala ya ombi lako kwa barua pepe.';

  @override
  String get emailInvalid => 'Barua pepe hii haionekani sahihi';

  @override
  String get typeOfEvent => 'Aina ya tukio';

  @override
  String get chooseEventType => 'Chagua aina ya tukio';

  @override
  String get eventTypeWedding => 'Harusi';

  @override
  String get eventTypeSendOff => 'Send-off';

  @override
  String get eventTypeKitchenParty => 'Kitchen party';

  @override
  String get eventTypeBirthday => 'Siku ya kuzaliwa';

  @override
  String get eventTypeCorporate => 'Tukio la kampuni';

  @override
  String get eventTypeOther => 'Nyingine';

  @override
  String get venue => 'Mahali';

  @override
  String get venueHint => 'Ukumbi, hoteli au mji';

  @override
  String get enterVenue => 'Weka mahali';

  @override
  String get chooseDateOrNotSure =>
      'Chagua tarehe, au weka alama kwenye “Sina uhakika”';

  @override
  String get notSureOfDate => 'Sina uhakika na tarehe bado';

  @override
  String get howManyGuests => 'Wageni wangapi?';

  @override
  String get chooseGuestRange => 'Chagua takriban idadi ya wageni';

  @override
  String get guestsUnder100 => 'Chini ya 100';

  @override
  String get anythingElse => 'Lolote jingine? (si lazima)';

  @override
  String get sendRequest => 'Tuma ombi';

  @override
  String get requestDisclaimer =>
      'Ni bure, bila masharti. Tunatumia taarifa zako kuwasiliana nawe kuhusu tukio hili tu.';

  @override
  String get date => 'Tarehe';

  @override
  String get notSureYet => 'Bado sina uhakika';

  @override
  String get requestUnreachable =>
      'Imeshindwa kufikia Cardly. Angalia intaneti yako kisha jaribu tena.';

  @override
  String get requestCheckFields => 'Angalia sehemu zilizowekewa alama.';

  @override
  String get requestTooMany =>
      'Maombi ni mengi kwa sasa. Tafadhali jaribu tena baada ya saa moja.';

  @override
  String get requestFailed =>
      'Hatukuweza kutuma ombi lako. Tafadhali jaribu tena.';

  @override
  String couldntOpenCallUs(String number) {
    return 'Imeshindwa kufungua. Tupigie kwa $number.';
  }

  @override
  String get requestWithUs => 'Ombi lako limetufikia.';

  @override
  String thanksRequestWithUs(String name) {
    return 'Asante, $name. Ombi lako limetufikia.';
  }

  @override
  String callYouOn(String phone) {
    return 'Tutakupigia kwa $phone ndani ya siku moja ya kazi.';
  }

  @override
  String get callYouSoon => 'Tutakupigia ndani ya siku moja ya kazi.';

  @override
  String emailedCopyTo(String email) {
    return 'Pia tumetuma nakala kwa $email.';
  }

  @override
  String get whatHappensNext => 'Kinachofuata';

  @override
  String get nextStep1 =>
      'Tunakupigia ili tukubaliane kuhusu kadi, orodha ya wageni na bei.';

  @override
  String get nextStep2 =>
      'Tunaandaa tukio lako na kukutumia SMS na barua pepe ili uchague nenosiri.';

  @override
  String get nextStep3 => 'Ingia hapa na tukio lako litakuwa tayari.';

  @override
  String get cantWait => 'Huwezi kusubiri? Wasiliana nasi sasa.';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get callUs => 'Tupigie';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get syncNow => 'Sawazisha sasa';

  @override
  String get activeEvent => 'Tukio linalotumika';

  @override
  String get noEventSelected => 'Hakuna tukio lililochaguliwa';

  @override
  String get syncCheckIns => 'Sawazisha waliofika';

  @override
  String waitingToSync(int count) {
    return '$count wanasubiri kusawazishwa';
  }

  @override
  String get allSynced => 'Vyote vimesawazishwa';

  @override
  String get serverConnection => 'Muunganisho wa seva';

  @override
  String get serverConnectionSubtitle => 'Simamia anwani ya seva';

  @override
  String get encryptionKey => 'Ufunguo wa usimbaji';

  @override
  String get encryptionKeySubtitle => 'Ufunguo wa kusoma QR code';

  @override
  String get faq => 'Maswali';

  @override
  String get faqSubtitle => 'Maswali yanayoulizwa mara kwa mara kuhusu Cardly';

  @override
  String get terms => 'Masharti ya huduma';

  @override
  String get termsSubtitle => 'Kanuni za kutumia Cardly';

  @override
  String get userPolicy => 'Sera ya mtumiaji';

  @override
  String get userPolicySubtitle => 'Jinsi taarifa zako zinavyotumika';

  @override
  String get logOut => 'Toka';

  @override
  String get logOutQuestion => 'Utoke?';

  @override
  String get logOutBody => 'Utahitaji kuingia tena ili kutumia programu.';

  @override
  String get serverUrlSaved => 'Anwani ya seva imehifadhiwa';

  @override
  String get keyMustBe64 => 'Ufunguo lazima uwe na herufi 64';

  @override
  String get eventKeySaved => 'Ufunguo wa tukio umehifadhiwa';

  @override
  String get keyRedownloaded => 'Ufunguo umepakuliwa upya';

  @override
  String get keyDownloadFailed => 'Imeshindwa kupakua ufunguo';

  @override
  String syncedSomeWaiting(int synced, int waiting) {
    return 'Imesawazisha $synced. $waiting bado zinasubiri, angalia mtandao.';
  }

  @override
  String get everythingSynced => 'Vyote vimesawazishwa';

  @override
  String syncedCheckIns(int count) {
    return 'Imesawazisha waliofika $count';
  }

  @override
  String get selectEventFirst => 'Chagua tukio kwanza';

  @override
  String get pasteKeyHelp =>
      'Bandika ufunguo wa herufi 64 wa kusoma QR code za wageni.';

  @override
  String get eventKey => 'Ufunguo wa tukio';

  @override
  String get eventKeyHint => 'Ufunguo wa herufi 64';

  @override
  String get saveKey => 'Hifadhi ufunguo';

  @override
  String get redownload => 'Pakua upya';

  @override
  String get dashCheckedIn => 'Amefika';

  @override
  String dashCheckedInPeople(int count) {
    return 'Amefika · watu $count';
  }

  @override
  String dashQueued(String label) {
    return '$label · inasubiri';
  }

  @override
  String get guestFallback => 'Mgeni';

  @override
  String get dashContributed => 'Amechangia';

  @override
  String get dashAddedAsGuest => 'Ameongezwa kama mgeni';

  @override
  String get dashSummary => 'Kwa ufupi';

  @override
  String get dashAllSettled => 'Yote yamelipwa';

  @override
  String get dashUnpaid => 'hawajalipa';

  @override
  String get dashRecentActivity => 'Shughuli za karibuni';

  @override
  String get dashTrends => 'Mwenendo';

  @override
  String dashOwesBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wageni $count bado wanadaiwa',
      one: 'Mgeni 1 bado anadaiwa',
    );
    return '$_temp0';
  }

  @override
  String get dashViewGuests => 'Tazama wageni';

  @override
  String get dashManageTeam => 'Simamia timu';

  @override
  String get dashViewReport => 'Tazama ripoti';

  @override
  String dashSyncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waliofika $count wanasubiri kusawazishwa',
      one: 'Aliyefika 1 anasubiri kusawazishwa',
    );
    return '$_temp0';
  }

  @override
  String dashOfflineQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hakuna mtandao · waliofika $count wamehifadhiwa',
      one: 'Hakuna mtandao · aliyefika 1 amehifadhiwa',
    );
    return '$_temp0';
  }

  @override
  String get dashPeople => 'Watu';

  @override
  String get dashEntered => 'Wamefika';

  @override
  String get dashPending => 'Bado';

  @override
  String get dashRate => 'Kiwango';

  @override
  String get dashDays => 'siku';

  @override
  String get dashHours => 'saa';

  @override
  String get dashMinutes => 'dak';

  @override
  String get dashSeconds => 'sek';

  @override
  String get dashNoGuestsAdded => 'Bado hujaongeza wageni';

  @override
  String get dashAddGuests => 'Ongeza wageni';

  @override
  String get dashNoTeam => 'Bado hakuna wanatimu';

  @override
  String get dashAddTeamMember => 'Ongeza mwanatimu';

  @override
  String get dashNoContributions => 'Bado hakuna michango iliyorekodiwa';

  @override
  String get dashSetUpContributions => 'Weka michango';

  @override
  String get dashNoCategory => 'Bila aina';

  @override
  String get dashContributionsCollected => 'Michango iliyokusanywa';

  @override
  String dashCollectedAmount(String amount) {
    return 'TZS $amount imekusanywa';
  }

  @override
  String dashTargetAmount(String amount) {
    return 'Lengo: TZS $amount';
  }

  @override
  String get dashByCategory => 'Kwa aina ya kadi';

  @override
  String dashGuestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wageni $count',
      one: 'Mgeni 1',
    );
    return '$_temp0';
  }

  @override
  String get dashNoGuestsYet => 'Bado hakuna wageni';

  @override
  String get dashImportGuests => 'Leta wageni ili uanze kufuatilia michango';

  @override
  String get dashNoActivity => 'Bado hakuna shughuli';

  @override
  String get timeNow => 'sasa hivi';

  @override
  String timeMinutesAgo(int count) {
    return 'dak $count zilizopita';
  }

  @override
  String timeHoursAgo(int count) {
    return 'saa $count zilizopita';
  }

  @override
  String timeDaysAgo(int count) {
    return 'siku $count zilizopita';
  }

  @override
  String get dashSelectEvent => 'Chagua tukio ili uone muhtasari wake';

  @override
  String get tryAgain => 'Jaribu tena';

  @override
  String get guestNotFound => 'Mgeni hajapatikana';

  @override
  String get checkInFailed => 'Imeshindikana kumpokea mgeni. Jaribu tena.';

  @override
  String get phoneCopied => 'Namba ya simu imenakiliwa';

  @override
  String get editGuest => 'Hariri mgeni';

  @override
  String get checkInGuest => 'Mpokee mgeni';

  @override
  String checkInProgress(int entered, int admits) {
    return 'Mpokee · $entered kati ya $admits wamefika';
  }

  @override
  String get tabOverview => 'Muhtasari';

  @override
  String get tabPayment => 'Malipo';

  @override
  String get guestProfile => 'Wasifu wa mgeni';

  @override
  String get amountPaid => 'Kiasi kilicholipwa';

  @override
  String get balance => 'Salio';

  @override
  String get yes => 'Ndiyo';

  @override
  String get no => 'Hapana';

  @override
  String get contact => 'Mawasiliano';

  @override
  String get mobileNumber => 'Namba ya simu';

  @override
  String get copyNumber => 'Nakili namba';

  @override
  String get checkInSection => 'Kufika';

  @override
  String get status => 'Hali';

  @override
  String get notCheckedIn => 'Bado hajafika';

  @override
  String get checkedInAt => 'Muda wa kufika';

  @override
  String get contribution => 'Mchango';

  @override
  String get category => 'Aina';

  @override
  String get notAssigned => 'Haijawekwa';

  @override
  String get targetAmount => 'Lengo';

  @override
  String get qrCard => 'Kadi ya QR';

  @override
  String get qrCardMessage => 'Ujumbe wa kadi ya QR';

  @override
  String get sent => 'Umetumwa';

  @override
  String get notSentYet => 'Bado haujatumwa';

  @override
  String get sentAt => 'Muda wa kutumwa';

  @override
  String get paymentSummary => 'Muhtasari wa malipo';

  @override
  String get balanceRemaining => 'Salio lililobaki';

  @override
  String percentOfTargetPaid(int percent) {
    return '$percent% ya lengo imelipwa';
  }

  @override
  String get paymentStatus => 'Hali ya malipo';

  @override
  String get statusFullyPaid => 'Amelipa yote';

  @override
  String get statusPartiallyPaid => 'Amelipa sehemu';

  @override
  String get statusUnpaid => 'Hajalipa';

  @override
  String get enterValidAmount => 'Weka kiasi sahihi';

  @override
  String get guestUpdated => 'Mgeni amesasishwa';

  @override
  String get updateGuestFailed => 'Imeshindikana kusasisha mgeni';

  @override
  String alsoOnCard(String phone, String name) {
    return '$phone pia yupo kwenye kadi ya $name';
  }

  @override
  String alsoGuestNotMerged(String phone, String name) {
    return '$phone pia ni mgeni $name mwenye maingizo au malipo, hivyo hajaunganishwa';
  }

  @override
  String mergeTitle(String name) {
    return 'Umuunganishe $name?';
  }

  @override
  String mergeBody(String phone, String name) {
    return '$phone tayari ni $name, mgeni mwenye kadi yake, hivyo angepata mialiko miwili. Umuunganishe kwenye kadi hii kama mwenzi?';
  }

  @override
  String get keepBoth => 'Acha wote wawili';

  @override
  String get merge => 'Unganisha';

  @override
  String get companions => 'Wenzi';

  @override
  String get companionsHint =>
      'Wengine wanaotumia kadi hii. Kila mwenye simu anapata mwaliko huo huo.';

  @override
  String get optional => 'Si lazima';

  @override
  String get removeCompanion => 'Ondoa mwenzi';

  @override
  String get addCompanion => 'Ongeza mwenzi';

  @override
  String get contributionCategory => 'Aina ya mchango';

  @override
  String get nameRequired => 'Jina linahitajika';

  @override
  String get peopleOnCard => 'Watu kwenye kadi hii';

  @override
  String alreadyEntered(int count) {
    return '$count wameshafika';
  }

  @override
  String get peopleOnCardHint => 'Idadi ya watu kadi hii inaowaruhusu kuingia';

  @override
  String get amountPaidTzs => 'Kiasi kilicholipwa (TZS)';

  @override
  String get pledgeTzs => 'Ahadi (TZS, si lazima)';

  @override
  String get pledgeHelper => 'Kiasi ambacho mgeni huyu ameahidi kuchangia';

  @override
  String get saveChanges => 'Hifadhi mabadiliko';

  @override
  String get categoryOptional => 'Aina (si lazima)';

  @override
  String get selectedCategory => 'Aina iliyochaguliwa';

  @override
  String get enterHowManyPeople => 'Weka idadi ya watu';

  @override
  String fromOneTo(int max) {
    return 'Kuanzia 1 hadi $max';
  }

  @override
  String cantBeFewer(int count) {
    return '$count wameshafika, hivyo haiwezi kuwa chini ya hapo';
  }

  @override
  String admitPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ruhusu watu $count',
      one: 'Ruhusu mtu 1',
    );
    return '$_temp0';
  }

  @override
  String get continueScanning => 'Endelea kuskani';

  @override
  String get cardUnknownNote =>
      'Kadi hii bado haipo kwenye orodha ya wageni ya simu hii, hivyo nafasi zake hazijulikani. Unaruhusu mtu mmoja. Sasisha orodha ya wageni mtandao ukirudi.';

  @override
  String get manualCheckInNote =>
      'Hakikisha huyu ndiye mtu aliye mlangoni. Hii inarekodiwa kama mapokezi ya mkono.';

  @override
  String get cardFullyUsed => 'Kadi imeshatumika yote';

  @override
  String get notAdmitted => 'Hajaruhusiwa';

  @override
  String get admitted => 'Ameruhusiwa';

  @override
  String get savedOnPhoneNote =>
      'Imehifadhiwa kwenye simu hii. Itasawazishwa yenyewe mtandao ukipatikana.';

  @override
  String overBy(int count) {
    return 'Imezidi kwa $count';
  }

  @override
  String get noPlacesLeft => 'Hakuna nafasi iliyobaki';

  @override
  String placesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nafasi $count zimebaki',
      one: 'Nafasi 1 imebaki',
    );
    return '$_temp0';
  }

  @override
  String enteredOf(int entered, int admits) {
    return '$entered kati ya $admits';
  }

  @override
  String get enteredWord => 'wamefika';

  @override
  String get firstEntry => 'Kuingia kwa kwanza';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watu $count',
      one: 'Mtu 1',
    );
    return '$_temp0';
  }

  @override
  String get waitingToSyncShort => 'inasubiri kusawazishwa';

  @override
  String get peopleEnteringNow => 'Watu wanaoingia sasa';

  @override
  String get oneFewer => 'Mmoja pungufu';

  @override
  String get oneMore => 'Mmoja zaidi';

  @override
  String get noCategoryAssigned => 'Hakuna aina iliyowekwa';

  @override
  String get invalidQr => 'QR code si sahihi';

  @override
  String get invalidQrBody =>
      'Imeshindikana kusoma code hii. Angalia ufunguo wa tukio kwenye Mipangilio.';

  @override
  String get addContribution => 'Ongeza mchango';

  @override
  String addContributionSelected(int count) {
    return 'Ongeza mchango ($count wamechaguliwa)';
  }

  @override
  String get tabStats => 'Takwimu';

  @override
  String get tabList => 'Orodha';

  @override
  String get searchByName => 'Tafuta kwa jina';

  @override
  String get collected => 'Zilizokusanywa';

  @override
  String get expected => 'Zinazotarajiwa';

  @override
  String get partial => 'Sehemu';

  @override
  String get outstanding => 'Zinazodaiwa';

  @override
  String get byCategoryTitle => 'Kwa aina';

  @override
  String get loadCategoryDataFailed => 'Imeshindikana kupakia takwimu za aina';

  @override
  String get noContributionsCollected => 'Bado hakuna michango iliyokusanywa';

  @override
  String get uncategorized => 'Bila aina';

  @override
  String get overTime => 'Kwa muda';

  @override
  String get loadContributionsFailed => 'Imeshindikana kupakia michango';

  @override
  String get filterAll => 'Wote';

  @override
  String get filterUnpaid => 'Hawajalipa';

  @override
  String get filterPartial => 'Sehemu';

  @override
  String get filterFull => 'Wamelipa';

  @override
  String get noContributionsFound => 'Hakuna michango iliyopatikana';

  @override
  String get noContributionsFoundHint =>
      'Jaribu kichujio kingine, au weka ahadi kwa mgeni ili uifuatilie hapa.';

  @override
  String get contributionCategories => 'Aina za michango';

  @override
  String get noCategoriesTapPlus =>
      'Bado hakuna aina.\nGusa + kuongeza Mmoja, Wawili, Familia na kadhalika.';

  @override
  String peoplePerCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watu $count kwa kadi',
      one: 'Mtu 1 kwa kadi',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Futa';

  @override
  String get deleteCategoryFailed => 'Imeshindikana kufuta aina';

  @override
  String get noGuestsFound => 'Hakuna wageni waliopatikana';

  @override
  String get clearAll => 'Ondoa wote';

  @override
  String get selectAll => 'Chagua wote';

  @override
  String get pickAtLeastOneGuest => 'Chagua angalau mgeni mmoja';

  @override
  String get enterPledgeOrPaid =>
      'Weka ahadi, kiasi kilicholipwa, au vyote viwili';

  @override
  String updatedGuests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wageni $count wamesasishwa',
      one: 'Mgeni 1 amesasishwa',
    );
    return '$_temp0';
  }

  @override
  String updatedSomeFailed(int succeeded, int failed) {
    return 'Wamesasishwa $succeeded, imeshindikana kwa $failed';
  }

  @override
  String get updateContributionFailed => 'Imeshindikana kusasisha mchango';

  @override
  String get searchGuestByName => 'Tafuta mgeni kwa jina';

  @override
  String get loadGuestsFailed => 'Imeshindikana kupakia wageni';

  @override
  String get pledgePerGuest => 'Ahadi kwa kila mgeni (TZS)';

  @override
  String get pledgePerGuestHelper => 'Walichoahidi kutoa';

  @override
  String get paidPerGuest => 'Kilicholipwa kwa kila mgeni (TZS)';

  @override
  String get paidPerGuestHelper => 'Pesa iliyopokelewa sasa';

  @override
  String saveForGuests(int count) {
    return 'Hifadhi kwa wageni $count';
  }

  @override
  String deleteCategoryTitle(String name) {
    return 'Ufute \"$name\"?';
  }

  @override
  String get deleteCategoryBody =>
      'Wageni wa aina hii watabaki bila aina. Ahadi na malipo yao hayataathirika.';

  @override
  String get categories => 'Aina';

  @override
  String get addCategory => 'Ongeza aina';

  @override
  String get loadCategoriesFailed => 'Imeshindikana kupakia aina.';

  @override
  String get noCategoriesUsePlus =>
      'Bado hakuna aina. Tumia kitufe cha + kuongeza.';

  @override
  String get updateExistingCardsTitle => 'Usasishe kadi zilizopo?';

  @override
  String updateExistingCardsBody(int from, int to) {
    return 'Kadi za aina hii ambazo bado zinaruhusu $from zinaweza kubadilika kuwa $to pia. Kadi zilizowekwa namba nyingine kwa mkono zitabaki kama zilivyo.';
  }

  @override
  String get onlyNewCards => 'Kadi mpya tu';

  @override
  String get updateCards => 'Sasisha kadi';

  @override
  String get enterCategoryName => 'Weka jina la aina';

  @override
  String get categorySaved => 'Aina imehifadhiwa';

  @override
  String categoryUpdatedCards(int count, int people) {
    return 'Aina imesasishwa · kadi $count sasa zinaruhusu $people';
  }

  @override
  String get categoryUpdated => 'Aina imesasishwa';

  @override
  String get saveCategoryFailed => 'Imeshindikana kuhifadhi aina';

  @override
  String get editCategory => 'Hariri aina';

  @override
  String get categoryName => 'Jina la aina';

  @override
  String get peoplePerCardLabel => 'Watu kwa kila kadi';

  @override
  String get peoplePerCardHelper =>
      'Idadi ya watu ambao kadi moja ya aina hii inawaruhusu kuingia, kwa mfano 2 kwa wanandoa. Kila kadi bado inaweza kubadilishwa.';

  @override
  String get saveCategory => 'Hifadhi aina';

  @override
  String get createMemberFailed =>
      'Imeshindikana kufungua akaunti ya mwanakamati';

  @override
  String get loadTeamFailed => 'Imeshindikana kupakia timu';

  @override
  String get nameAndEmailRequired => 'Jina na barua pepe vinahitajika';

  @override
  String get passwordMin6 => 'Nenosiri liwe na herufi 6 au zaidi';

  @override
  String get memberCreated => 'Akaunti ya mwanakamati imefunguliwa';

  @override
  String get addKamatiMember => 'Ongeza mwanakamati';

  @override
  String get addKamatiMemberLead =>
      'Fungua akaunti kwa mwanakamati ili akusaidie kusimamia tukio lako.';

  @override
  String get fullName => 'Jina kamili';

  @override
  String get atLeast6Chars => 'Herufi 6 au zaidi';

  @override
  String get creating => 'Inafungua…';

  @override
  String get createMember => 'Fungua akaunti';

  @override
  String get members => 'Wanakamati';

  @override
  String addedOn(String date) {
    return 'Aliongezwa $date';
  }

  @override
  String get noKamatiMembers => 'Bado hakuna wanakamati';

  @override
  String get noKamatiMembersHint =>
      'Gusa + kuongeza wanakamati watakaosaidia kuskani wageni na kusimamia tukio lako.';

  @override
  String get scanCard => 'Skani kadi';

  @override
  String get pickEventToCheckIn => 'Chagua tukio ili uanze kupokea wageni.';

  @override
  String get loadGuestListFailed => 'Imeshindikana kupakia orodha ya wageni';

  @override
  String get pullToRetry => 'Vuta chini ujaribu tena.';

  @override
  String get noGuestsOnEvent => 'Bado hakuna wageni kwenye tukio hili';

  @override
  String get noGuestListOnPhone => 'Simu hii bado haina orodha ya wageni';

  @override
  String get noGuestsOnEventHint =>
      'Wageni walioongezwa kwenye portal au kwenye kichupo cha Wageni wataonekana hapa.';

  @override
  String get noGuestListOnPhoneHint =>
      'Unganisha intaneti mara moja ili kuipakua. Kuskani kunafanya kazi hata bila mtandao.';

  @override
  String get tabArrived => 'Waliofika';

  @override
  String get tabStillToCome => 'Bado kufika';

  @override
  String get peopleIn => 'Walioingia';

  @override
  String get cardsUsed => 'Kadi zilizotumika';

  @override
  String get partlyIn => 'Wameingia sehemu';

  @override
  String waitingSyncPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Watu $count walioruhusiwa kwenye simu hii wanasubiri kusawazishwa',
      one: 'Mtu 1 aliyeruhusiwa kwenye simu hii anasubiri kusawazishwa',
    );
    return '$_temp0';
  }

  @override
  String get byCardType => 'Kwa aina ya kadi';

  @override
  String get everyoneIsIn => 'Wote wameingia';

  @override
  String categoryProgress(int toCome, int arrived, int cards) {
    return '$toCome bado kufika, kadi $arrived kati ya $cards zimetumika';
  }

  @override
  String get filterArrived => 'Chuja wageni waliofika';

  @override
  String get filterToCome => 'Chuja wageni ambao bado kufika';

  @override
  String get allCardTypes => 'Aina zote za kadi';

  @override
  String cardTypeCards(String type) {
    return 'Kadi za $type';
  }

  @override
  String get showAllCardTypes => 'Onyesha aina zote za kadi';

  @override
  String get searchByNameOrPhone => 'Tafuta kwa jina au simu';

  @override
  String get filterByCardType => 'Chuja kwa aina ya kadi';

  @override
  String get cardType => 'Aina ya kadi';

  @override
  String typeAtTime(String type, String time) {
    return '$type, $time';
  }

  @override
  String typePartlyIn(String type, int entered, int admits) {
    return '$type, $entered kati ya $admits wameingia';
  }

  @override
  String get waitingSyncTooltip =>
      'Ameruhusiwa kwenye simu hii, anasubiri kusawazishwa';

  @override
  String placesLeftShort(int count) {
    return '$count zimebaki';
  }

  @override
  String enteredShort(int entered, int admits) {
    return '$entered/$admits wameingia';
  }

  @override
  String get noSearchMatch => 'Hakuna mgeni anayelingana na utafutaji wako';

  @override
  String get noSearchMatchHint => 'Angalia tahajia au futa utafutaji.';

  @override
  String get noOneInYet => 'Bado hakuna aliyeingia';

  @override
  String noOneOfTypeInYet(String type) {
    return 'Bado hakuna mwenye kadi ya $type aliyeingia';
  }

  @override
  String get tapScanWhenArrives => 'Gusa Skani kadi mgeni wa kwanza akifika.';

  @override
  String everyTypeIn(String type) {
    return 'Kadi zote za $type zimeingia';
  }

  @override
  String get noPlacesToFill => 'Hakuna nafasi iliyobaki.';

  @override
  String get online => 'Mtandaoni';

  @override
  String get offline => 'Nje ya mtandao';

  @override
  String get noCardType => 'Bila aina ya kadi';

  @override
  String get backToDoor => 'Rudi kwenye muhtasari wa mlangoni';

  @override
  String get keepsScanning => 'Inaendelea kuskani baada ya kila mgeni';

  @override
  String peopleInOf(int peopleIn, int expected) {
    return 'Watu $peopleIn kati ya $expected wameingia';
  }

  @override
  String get flashlightOff => 'Zima tochi';

  @override
  String get flashlightOn => 'Washa tochi';

  @override
  String get checkingCard => 'Inakagua kadi…';

  @override
  String get alignQr => 'Weka QR code ndani ya fremu. Bana kukuza.';

  @override
  String get zoomOut => 'Punguza';

  @override
  String get zoomIn => 'Kuza';

  @override
  String get zoom => 'Kuza';

  @override
  String get alreadyCheckedIn => 'Ameshaingia';

  @override
  String get serverRefusedCheckIn => 'Seva imekataa kumpokea mgeni huyu';

  @override
  String get addGuestManually => 'Ongeza mgeni kwa mkono';

  @override
  String get importFromContacts => 'Leta kutoka kwenye anwani';

  @override
  String get offlineLocalGuests =>
      'Nje ya mtandao · inaonyesha wageni waliohifadhiwa kwenye simu hii tu';

  @override
  String get pending => 'Bado';

  @override
  String get noGuestsFoundHint =>
      'Jaribu kichujio kingine au gusa + kuongeza mgeni.';

  @override
  String get loadGuestsFailedTitle => 'Imeshindikana kupakia wageni';

  @override
  String get guestAdded => 'Mgeni ameongezwa';

  @override
  String get addGuestFailed =>
      'Imeshindikana kuongeza mgeni. Tafadhali jaribu tena.';

  @override
  String get addGuest => 'Ongeza mgeni';

  @override
  String get addGuestLead =>
      'Weka taarifa zake kwa mkono badala ya kuchagua kutoka kwenye anwani.';

  @override
  String leaveEmptyForDefault(int count) {
    return 'Acha wazi ili kutumia $count ya aina hii';
  }

  @override
  String get contactsPermissionNeeded =>
      'Ruhusa ya anwani inahitajika ili kuleta wageni.';

  @override
  String get loadContactsFailed => 'Imeshindikana kupakia anwani.';

  @override
  String get importNeedsInternet => 'Kuleta wageni kunahitaji intaneti';

  @override
  String importResult(int inserted, int skipped) {
    return '$inserted wameongezwa, $skipped wamerukwa';
  }

  @override
  String get importFailed =>
      'Imeshindikana kuleta wageni. Tafadhali jaribu tena.';

  @override
  String get importContacts => 'Leta anwani';

  @override
  String get deselectAll => 'Ondoa zote';

  @override
  String contactsSelected(int count, int selected) {
    return 'Anwani $count · $selected zimechaguliwa';
  }

  @override
  String get noContactsWithPhones => 'Hakuna anwani zenye namba za simu';

  @override
  String get importing => 'Inaleta…';

  @override
  String importCount(int count) {
    return 'Leta ($count)';
  }

  @override
  String get guestPhoneExists => 'Tayari kuna mgeni mwenye namba hii ya simu';

  @override
  String get trackMyRequest => 'Fuatilia ombi lako';

  @override
  String requestSentTo(String name) {
    return 'Ombi limetumwa, $name';
  }

  @override
  String get requestSpokenTitle => 'Tumezungumza nawe';

  @override
  String get requestSettingUpLead =>
      'Tunaandaa tukio lako. Tutakutumia SMS likiwa tayari.';

  @override
  String get requestReadyTitle => 'Tukio lako liko tayari';

  @override
  String requestReadyLead(String phone) {
    return 'Chagua nenosiri ili ulifungue. Utaingia kwa $phone.';
  }

  @override
  String get requestClosedTitle => 'Ombi limefungwa';

  @override
  String get requestClosedLead =>
      'Ombi hili halitaendelea. Mipango ikibadilika, tutumie ombi jipya.';

  @override
  String get stepReceived => 'Tumelipokea';

  @override
  String get stepWeCall => 'Tutakupigia simu';

  @override
  String get stepWeCalled => 'Tumekupigia simu';

  @override
  String get stepCallHint => 'Kukubaliana kuhusu maelezo na bei';

  @override
  String get stepSettingUp => 'Tunaandaa tukio lako';

  @override
  String get stepSetUp => 'Tukio lako limeandaliwa';

  @override
  String get stepSetUpHint => 'Kisha unachagua nenosiri lako';

  @override
  String get choosePasswordButton => 'Chagua nenosiri lako';

  @override
  String get sendNewRequest => 'Tuma ombi jipya';

  @override
  String get checkingForUpdates => 'Inatafuta taarifa mpya...';

  @override
  String statusUpdatedAt(String time) {
    return 'Imesasishwa $time';
  }

  @override
  String get statusRefreshFailed =>
      'Imeshindikana kupata taarifa mpya. Hii ni hali ya mwisho tuliyokuwa nayo.';

  @override
  String get savePassword => 'Hifadhi nenosiri';

  @override
  String get passwordSavedSignIn =>
      'Nenosiri limehifadhiwa. Gusa Ingia ili kufungua tukio lako.';

  @override
  String get updateReadyTitle => 'Sasisho limepakuliwa';

  @override
  String get updateReadyBody =>
      'Anzisha upya Cardly ili kukamilisha kusasisha.';

  @override
  String get updateRestart => 'Anzisha upya';

  @override
  String get selectEventTitle => 'Chagua tukio';

  @override
  String get eventsLoadFailedTitle => 'Imeshindikana kupakia matukio yako';

  @override
  String get eventsLoadFailedBody =>
      'Angalia muunganisho wako wa intaneti kisha ujaribu tena. Ikiendelea, toka kisha uingie tena.';

  @override
  String get noEventsTitle => 'Bado hakuna matukio';

  @override
  String get noEventsBody =>
      'Matukio unayoshiriki yataonekana hapa. Vuta chini kuangalia tena.';

  @override
  String get eventKeyMissing => 'Ufunguo haupo';

  @override
  String get noVenue => 'Hakuna ukumbi';

  @override
  String get eventKeySavedChip => 'Ufunguo umehifadhiwa';

  @override
  String get whereSendCodeTitle => 'Tukutumie msimbo wapi?';

  @override
  String whereSendCodeLead(String name) {
    return 'Tutakutumia msimbo wa tarakimu 6 kuhakikisha ni wewe, $name.';
  }

  @override
  String get viaTextMessage => 'Ujumbe mfupi (SMS)';

  @override
  String viaTextTo(String hint) {
    return 'Kwenye simu inayoishia $hint';
  }

  @override
  String get viaEmail => 'Barua pepe';

  @override
  String viaEmailTo(String hint) {
    return 'Kwenda $hint';
  }

  @override
  String get cantUseEither => 'Huwezi kutumia vyovyote?';

  @override
  String get whatsAppUsLink => 'Tuandikie WhatsApp';

  @override
  String codeTextedTo(String hint) {
    return 'Tumetuma msimbo wa tarakimu 6 kwa SMS kwenye simu inayoishia $hint.';
  }

  @override
  String codeEmailedTo(String hint) {
    return 'Tumetuma msimbo wa tarakimu 6 kwa barua pepe kwenda $hint.';
  }

  @override
  String get noSmsYet => 'Bado hujapata SMS?';

  @override
  String get noEmailYet => 'Bado hujapata barua pepe?';

  @override
  String sendToInstead(String hint) {
    return 'Ituma kwenda $hint badala yake';
  }

  @override
  String get eventNotReadyYet =>
      'Tukio lako bado halijawa tayari. Vuta chini kwenye ukurasa wa ombi kuangalia tena, au tuandikie WhatsApp.';

  @override
  String get chooseCategoryTitle => 'Chagua aina';

  @override
  String get chooseCategoryLead =>
      'Inaweka idadi ya watu kadi inaruhusu. Unaweza kuibadilisha kwa kila mgeni.';

  @override
  String admitsPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inaruhusu watu $count',
      one: 'Inaruhusu mtu 1',
    );
    return '$_temp0';
  }

  @override
  String get newCategoryButton => 'Aina mpya';

  @override
  String get tapToChoose => 'Gusa kuchagua';

  @override
  String get importFromExcel => 'Leta kutoka Excel';

  @override
  String get excelImportLead =>
      'Tumia faili la Excel au CSV lililopangwa hivi, mgeni mmoja kila mstari. Pakua mfano uanzie hapo.';

  @override
  String get chooseFile => 'Chagua faili';

  @override
  String get chooseAnotherFile => 'Chagua faili jingine';

  @override
  String readingFile(String file) {
    return 'Inasoma $file…';
  }

  @override
  String excelWillAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wageni $count wataongezwa',
      one: 'Mgeni 1 ataongezwa',
      zero: 'Hakuna wageni wapya wa kuongeza',
    );
    return '$_temp0';
  }

  @override
  String excelMoreRows(int count) {
    return 'na wengine $count';
  }

  @override
  String get excelNewCategories => 'Aina mpya';

  @override
  String excelDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tayari wapo kwenye orodha',
      one: '1 tayari yupo kwenye orodha',
    );
    return '$_temp0';
  }

  @override
  String get excelDuplicatesHint =>
      'Namba ya simu sawa na mgeni uliye naye, au imerudiwa kwenye faili. Hawa wanarukwa.';

  @override
  String excelProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mistari $count haiwezi kuletwa',
      one: 'Mstari 1 hauwezi kuletwa',
    );
    return '$_temp0';
  }

  @override
  String get excelProblemsHint =>
      'Rekebisha haya kwenye faili kisha ulete tena. Wageni walioongezwa tayari wanarukwa.';

  @override
  String excelRow(int row) {
    return 'Mstari $row';
  }

  @override
  String excelImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Leta wageni $count',
      one: 'Leta mgeni 1',
    );
    return '$_temp0';
  }

  @override
  String excelImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wageni $count wameongezwa',
      one: 'Mgeni 1 ameongezwa',
    );
    return '$_temp0';
  }

  @override
  String get excelReadFailed =>
      'Imeshindikana kusoma faili hilo. Tafadhali jaribu tena.';

  @override
  String get excelFileTooBig => 'Faili hilo ni kubwa mno. Kikomo ni MB 2.';

  @override
  String get sampleSheet => 'Mfano';

  @override
  String get downloadSampleSheet => 'Pakua faili la mfano';

  @override
  String get sampleSheetSaved =>
      'Mfano umehifadhiwa. Ujaze, kisha uchague hapa.';

  @override
  String get sampleSheetFailed =>
      'Imeshindikana kupakua mfano. Tafadhali jaribu tena.';

  @override
  String get setupLinkChecking => 'Tunakagua kiungo chako...';

  @override
  String get setupLinkUsedTitle => 'Kiungo hiki kimeshatumika';

  @override
  String get setupLinkUsedBody =>
      'Nenosiri lako limewekwa. Ingia nalo. Ukilisahau, gusa Umesahau nenosiri kwenye skrini ya kuingia.';

  @override
  String get setupLinkExpiredTitle => 'Muda wa kiungo hiki umeisha';

  @override
  String get setupLinkExpiredBody =>
      'Viungo hufanya kazi kwa siku 7. Tutumie WhatsApp na tutakutumia kipya.';

  @override
  String get setupLinkInvalidTitle => 'Kiungo hiki hakifanyi kazi';

  @override
  String get setupLinkInvalidBody =>
      'Fungua tena kiungo kilicho kwenye SMS au barua pepe yako, au tutumie WhatsApp tukutumie kipya.';

  @override
  String get setupLinkCheckFailed =>
      'Hatukuweza kukagua kiungo chako. Angalia intaneti yako kisha ujaribu tena.';

  @override
  String get goToSignIn => 'Nenda kuingia';

  @override
  String setupSavedWhileSignedIn(String signInWith) {
    return 'Nenosiri limehifadhiwa. Toka, kisha uingie kwa $signInWith.';
  }

  @override
  String get updateAlreadyLatest => 'Una toleo jipya zaidi la Cardly.';

  @override
  String get updateCheckFailed =>
      'Hatukuweza kuangalia masasisho. Angalia intaneti yako kisha ujaribu tena.';

  @override
  String get updateAvailableTitle => 'Sasisho linapatikana';

  @override
  String updateReadyToInstall(String version) {
    return 'Toleo $version liko tayari kusakinishwa.';
  }

  @override
  String get updateRequired =>
      'Sasisho hili linahitajika ili uendelee kutumia Cardly.';

  @override
  String get updateWhatsNew => 'Kipya ni nini';

  @override
  String get updateNow => 'Sasisha';

  @override
  String get updateLater => 'Baadaye';

  @override
  String updateDownloading(String version) {
    return 'Inapakua toleo $version...';
  }

  @override
  String get updateDownloadingShort => 'Inapakua...';

  @override
  String get updateInstallHint => 'Android itakuomba uthibitishe usakinishaji.';

  @override
  String get updateDownloadFailed =>
      'Upakuaji haukukamilika. Angalia intaneti yako kisha ujaribu tena.';
}
