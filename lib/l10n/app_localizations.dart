import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languageSheetTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get genericError;

  /// No description provided for @couldNotOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page'**
  String get couldNotOpenPage;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get navGuests;

  /// No description provided for @navContributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get navContributions;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcomeSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Every guest. Every moment. Perfectly managed.'**
  String get welcomeSlide1Title;

  /// No description provided for @welcomeSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Digital invitation cards, check-in at the door and contributions, all in one place.'**
  String get welcomeSlide1Body;

  /// No description provided for @welcomeSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Celebrate with confidence'**
  String get welcomeSlide2Title;

  /// No description provided for @welcomeSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Scan guests at the door, track check-ins and stay in control.'**
  String get welcomeSlide2Body;

  /// No description provided for @planEventWithCardly.
  ///
  /// In en, this message translates to:
  /// **'Plan an event with Cardly'**
  String get planEventWithCardly;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @invitedNote.
  ///
  /// In en, this message translates to:
  /// **'Invited to an event? Your card comes by SMS. You don\'t need an account.'**
  String get invitedNote;

  /// No description provided for @closeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Close sign in'**
  String get closeSignIn;

  /// No description provided for @newToCardly.
  ///
  /// In en, this message translates to:
  /// **'New to Cardly?'**
  String get newToCardly;

  /// No description provided for @planAnEvent.
  ///
  /// In en, this message translates to:
  /// **'Plan an event'**
  String get planAnEvent;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the email or phone number Cardly set up for you.'**
  String get signInSubtitle;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get emailOrPhone;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com or 0712 345 678'**
  String get emailOrPhoneHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @hideServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Hide server URL'**
  String get hideServerUrl;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @loginMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number, and your password.'**
  String get loginMissingFields;

  /// No description provided for @loginCheckServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Check the server URL under Advanced.'**
  String get loginCheckServerUrl;

  /// No description provided for @loginUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from the server.'**
  String get loginUnexpected;

  /// No description provided for @loginUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your internet connection.'**
  String get loginUnreachable;

  /// No description provided for @loginBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server\'s security certificate isn\'t valid.'**
  String get loginBadCertificate;

  /// No description provided for @loginWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password doesn\'t match this email or phone number. Try again, or tap Forgot password.'**
  String get loginWrongPassword;

  /// No description provided for @loginNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This account isn\'t allowed to use the Cardly app.'**
  String get loginNotAllowed;

  /// No description provided for @loginNotFound.
  ///
  /// In en, this message translates to:
  /// **'Login service not found on this server.'**
  String get loginNotFound;

  /// No description provided for @serverProblem.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Please try again shortly.'**
  String get serverProblem;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotTitle;

  /// No description provided for @enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCodeTitle;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordTitle;

  /// No description provided for @enterIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number.'**
  String get enterIdentifier;

  /// No description provided for @newCodeSent.
  ///
  /// In en, this message translates to:
  /// **'New code sent.'**
  String get newCodeSent;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get enterSixDigitCode;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords don\'t match.'**
  String get passwordsDontMatch;

  /// No description provided for @passwordChangedSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Password changed. You are signed in.'**
  String get passwordChangedSignedIn;

  /// No description provided for @forgotLead.
  ///
  /// In en, this message translates to:
  /// **'Enter the email or phone number on your account. We\'ll send you a 6-digit code.'**
  String get forgotLead;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @codeSentLead.
  ///
  /// In en, this message translates to:
  /// **'If {destination} is on a Cardly account, we\'ve sent it a 6-digit code. It works for 10 minutes.'**
  String codeSentLead(String destination);

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Send again in {time}'**
  String resendIn(String time);

  /// No description provided for @sendCodeAgain.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get sendCodeAgain;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @chooseNewPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for {name}.'**
  String chooseNewPasswordFor(String name);

  /// No description provided for @chooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password.'**
  String get chooseNewPassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get passwordHelper;

  /// No description provided for @typeItAgain.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get typeItAgain;

  /// No description provided for @saveAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Save and sign in'**
  String get saveAndSignIn;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @lostAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No longer have that number or email?'**
  String get lostAccessTitle;

  /// No description provided for @lostAccessBody.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp us on {number} and we\'ll help you back in.'**
  String lostAccessBody(String number);

  /// No description provided for @openWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get openWhatsApp;

  /// No description provided for @whatsAppUsOn.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp us on {number}.'**
  String whatsAppUsOn(String number);

  /// No description provided for @planYourEvent.
  ///
  /// In en, this message translates to:
  /// **'Plan your event'**
  String get planYourEvent;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfTotal(int current, int total);

  /// No description provided for @stepEventHeading.
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get stepEventHeading;

  /// No description provided for @stepYouHeading.
  ///
  /// In en, this message translates to:
  /// **'How can we reach you?'**
  String get stepYouHeading;

  /// No description provided for @stepReviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Check and send'**
  String get stepReviewHeading;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @yourEvent.
  ///
  /// In en, this message translates to:
  /// **'Your event'**
  String get yourEvent;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @eventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventLabel;

  /// No description provided for @dateOfEvent.
  ///
  /// In en, this message translates to:
  /// **'Date of the event'**
  String get dateOfEvent;

  /// No description provided for @fillHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Fill in the highlighted parts.'**
  String get fillHighlighted;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYou;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterLastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit number'**
  String get enterValidPhone;

  /// No description provided for @phoneContactHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll call or WhatsApp this number.'**
  String get phoneContactHint;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @emailCopyHelper.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a copy of your request.'**
  String get emailCopyHelper;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'This email doesn\'t look right'**
  String get emailInvalid;

  /// No description provided for @typeOfEvent.
  ///
  /// In en, this message translates to:
  /// **'Type of event'**
  String get typeOfEvent;

  /// No description provided for @chooseEventType.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of event'**
  String get chooseEventType;

  /// No description provided for @eventTypeWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get eventTypeWedding;

  /// No description provided for @eventTypeSendOff.
  ///
  /// In en, this message translates to:
  /// **'Send-off'**
  String get eventTypeSendOff;

  /// No description provided for @eventTypeKitchenParty.
  ///
  /// In en, this message translates to:
  /// **'Kitchen party'**
  String get eventTypeKitchenParty;

  /// No description provided for @eventTypeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventTypeBirthday;

  /// No description provided for @eventTypeCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get eventTypeCorporate;

  /// No description provided for @eventTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get eventTypeOther;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venue;

  /// No description provided for @venueHint.
  ///
  /// In en, this message translates to:
  /// **'Hall, hotel or town'**
  String get venueHint;

  /// No description provided for @enterVenue.
  ///
  /// In en, this message translates to:
  /// **'Enter the venue'**
  String get enterVenue;

  /// No description provided for @chooseDateOrNotSure.
  ///
  /// In en, this message translates to:
  /// **'Choose a date, or tick “Not sure”'**
  String get chooseDateOrNotSure;

  /// No description provided for @notSureOfDate.
  ///
  /// In en, this message translates to:
  /// **'Not sure of the date yet'**
  String get notSureOfDate;

  /// No description provided for @howManyGuests.
  ///
  /// In en, this message translates to:
  /// **'How many guests?'**
  String get howManyGuests;

  /// No description provided for @chooseGuestRange.
  ///
  /// In en, this message translates to:
  /// **'Choose roughly how many guests'**
  String get chooseGuestRange;

  /// No description provided for @guestsUnder100.
  ///
  /// In en, this message translates to:
  /// **'Under 100'**
  String get guestsUnder100;

  /// No description provided for @anythingElse.
  ///
  /// In en, this message translates to:
  /// **'Anything else? (optional)'**
  String get anythingElse;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @requestDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Free, no commitment. We only use your details to contact you about this event.'**
  String get requestDisclaimer;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @notSureYet.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get notSureYet;

  /// No description provided for @requestUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Cardly. Check your internet connection and try again.'**
  String get requestUnreachable;

  /// No description provided for @requestCheckFields.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields.'**
  String get requestCheckFields;

  /// No description provided for @requestTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many requests right now. Please try again in an hour.'**
  String get requestTooMany;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your request. Please try again.'**
  String get requestFailed;

  /// No description provided for @couldntOpenCallUs.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that. Call us on {number}.'**
  String couldntOpenCallUs(String number);

  /// No description provided for @requestWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your request is with us.'**
  String get requestWithUs;

  /// No description provided for @thanksRequestWithUs.
  ///
  /// In en, this message translates to:
  /// **'Thanks, {name}. Your request is with us.'**
  String thanksRequestWithUs(String name);

  /// No description provided for @callYouOn.
  ///
  /// In en, this message translates to:
  /// **'We\'ll call you on {phone} within one working day.'**
  String callYouOn(String phone);

  /// No description provided for @callYouSoon.
  ///
  /// In en, this message translates to:
  /// **'We\'ll call you within one working day.'**
  String get callYouSoon;

  /// No description provided for @emailedCopyTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve also emailed a copy to {email}.'**
  String emailedCopyTo(String email);

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @nextStep1.
  ///
  /// In en, this message translates to:
  /// **'We call to agree on the cards, the guest list and the price.'**
  String get nextStep1;

  /// No description provided for @nextStep2.
  ///
  /// In en, this message translates to:
  /// **'We set up your event and send you an SMS and email to choose a password.'**
  String get nextStep2;

  /// No description provided for @nextStep3.
  ///
  /// In en, this message translates to:
  /// **'Sign in here and your event is ready.'**
  String get nextStep3;

  /// No description provided for @cantWait.
  ///
  /// In en, this message translates to:
  /// **'Can\'t wait? Reach us now.'**
  String get cantWait;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get callUs;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @activeEvent.
  ///
  /// In en, this message translates to:
  /// **'Active event'**
  String get activeEvent;

  /// No description provided for @noEventSelected.
  ///
  /// In en, this message translates to:
  /// **'No event selected'**
  String get noEventSelected;

  /// No description provided for @syncCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Sync check-ins'**
  String get syncCheckIns;

  /// No description provided for @waitingToSync.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to sync'**
  String waitingToSync(int count);

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get allSynced;

  /// No description provided for @serverConnection.
  ///
  /// In en, this message translates to:
  /// **'Server connection'**
  String get serverConnection;

  /// No description provided for @serverConnectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage API server URL'**
  String get serverConnectionSubtitle;

  /// No description provided for @encryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Encryption key'**
  String get encryptionKey;

  /// No description provided for @encryptionKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'QR code decryption key'**
  String get encryptionKeySubtitle;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Common questions about Cardly'**
  String get faqSubtitle;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get terms;

  /// No description provided for @termsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rules for using Cardly'**
  String get termsSubtitle;

  /// No description provided for @userPolicy.
  ///
  /// In en, this message translates to:
  /// **'User policy'**
  String get userPolicy;

  /// No description provided for @userPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your data is handled'**
  String get userPolicySubtitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use the app.'**
  String get logOutBody;

  /// No description provided for @serverUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'Server URL saved'**
  String get serverUrlSaved;

  /// No description provided for @keyMustBe64.
  ///
  /// In en, this message translates to:
  /// **'Key must be 64 hex characters'**
  String get keyMustBe64;

  /// No description provided for @eventKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Event key saved'**
  String get eventKeySaved;

  /// No description provided for @keyRedownloaded.
  ///
  /// In en, this message translates to:
  /// **'Key re-downloaded'**
  String get keyRedownloaded;

  /// No description provided for @keyDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download key'**
  String get keyDownloadFailed;

  /// No description provided for @syncedSomeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced}. {waiting} still waiting, check the network.'**
  String syncedSomeWaiting(int synced, int waiting);

  /// No description provided for @everythingSynced.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get everythingSynced;

  /// No description provided for @syncedCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} check-ins'**
  String syncedCheckIns(int count);

  /// No description provided for @selectEventFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an event first'**
  String get selectEventFirst;

  /// No description provided for @pasteKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the 64-character key for decrypting guest QR codes.'**
  String get pasteKeyHelp;

  /// No description provided for @eventKey.
  ///
  /// In en, this message translates to:
  /// **'Event key'**
  String get eventKey;

  /// No description provided for @eventKeyHint.
  ///
  /// In en, this message translates to:
  /// **'64-character hex key'**
  String get eventKeyHint;

  /// No description provided for @saveKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get saveKey;

  /// No description provided for @redownload.
  ///
  /// In en, this message translates to:
  /// **'Re-download'**
  String get redownload;

  /// No description provided for @dashCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get dashCheckedIn;

  /// No description provided for @dashCheckedInPeople.
  ///
  /// In en, this message translates to:
  /// **'Checked in · {count} people'**
  String dashCheckedInPeople(int count);

  /// No description provided for @dashQueued.
  ///
  /// In en, this message translates to:
  /// **'{label} · queued'**
  String dashQueued(String label);

  /// No description provided for @guestFallback.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestFallback;

  /// No description provided for @dashContributed.
  ///
  /// In en, this message translates to:
  /// **'Contributed'**
  String get dashContributed;

  /// No description provided for @dashAddedAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Added as guest'**
  String get dashAddedAsGuest;

  /// No description provided for @dashSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dashSummary;

  /// No description provided for @dashAllSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get dashAllSettled;

  /// No description provided for @dashUnpaid.
  ///
  /// In en, this message translates to:
  /// **'unpaid'**
  String get dashUnpaid;

  /// No description provided for @dashRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashRecentActivity;

  /// No description provided for @dashTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashTrends;

  /// No description provided for @dashOwesBalance.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest still owes a balance} other{{count} guests still owe a balance}}'**
  String dashOwesBalance(int count);

  /// No description provided for @dashViewGuests.
  ///
  /// In en, this message translates to:
  /// **'View guests'**
  String get dashViewGuests;

  /// No description provided for @dashManageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage team'**
  String get dashManageTeam;

  /// No description provided for @dashViewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get dashViewReport;

  /// No description provided for @dashSyncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 check-in waiting to sync} other{{count} check-ins waiting to sync}}'**
  String dashSyncWaiting(int count);

  /// No description provided for @dashOfflineQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Offline · 1 check-in queued} other{Offline · {count} check-ins queued}}'**
  String dashOfflineQueued(int count);

  /// No description provided for @dashPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get dashPeople;

  /// No description provided for @dashEntered.
  ///
  /// In en, this message translates to:
  /// **'Entered'**
  String get dashEntered;

  /// No description provided for @dashPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashPending;

  /// No description provided for @dashRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get dashRate;

  /// No description provided for @dashDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get dashDays;

  /// No description provided for @dashHours.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get dashHours;

  /// No description provided for @dashMinutes.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get dashMinutes;

  /// No description provided for @dashSeconds.
  ///
  /// In en, this message translates to:
  /// **'secs'**
  String get dashSeconds;

  /// No description provided for @dashNoGuestsAdded.
  ///
  /// In en, this message translates to:
  /// **'No guests added yet'**
  String get dashNoGuestsAdded;

  /// No description provided for @dashAddGuests.
  ///
  /// In en, this message translates to:
  /// **'Add guests'**
  String get dashAddGuests;

  /// No description provided for @dashNoTeam.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get dashNoTeam;

  /// No description provided for @dashAddTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Add team member'**
  String get dashAddTeamMember;

  /// No description provided for @dashNoContributions.
  ///
  /// In en, this message translates to:
  /// **'No contributions recorded yet'**
  String get dashNoContributions;

  /// No description provided for @dashSetUpContributions.
  ///
  /// In en, this message translates to:
  /// **'Set up contributions'**
  String get dashSetUpContributions;

  /// No description provided for @dashNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get dashNoCategory;

  /// No description provided for @dashContributionsCollected.
  ///
  /// In en, this message translates to:
  /// **'Contributions collected'**
  String get dashContributionsCollected;

  /// No description provided for @dashCollectedAmount.
  ///
  /// In en, this message translates to:
  /// **'TZS {amount} collected'**
  String dashCollectedAmount(String amount);

  /// No description provided for @dashTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target: TZS {amount}'**
  String dashTargetAmount(String amount);

  /// No description provided for @dashByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get dashByCategory;

  /// No description provided for @dashGuestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String dashGuestCount(int count);

  /// No description provided for @dashNoGuestsYet.
  ///
  /// In en, this message translates to:
  /// **'No guests yet'**
  String get dashNoGuestsYet;

  /// No description provided for @dashImportGuests.
  ///
  /// In en, this message translates to:
  /// **'Import guests to start tracking contributions'**
  String get dashImportGuests;

  /// No description provided for @dashNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get dashNoActivity;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @dashSelectEvent.
  ///
  /// In en, this message translates to:
  /// **'Select an event to view your dashboard'**
  String get dashSelectEvent;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @guestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Guest not found'**
  String get guestNotFound;

  /// No description provided for @checkInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed. Try again.'**
  String get checkInFailed;

  /// No description provided for @phoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneCopied;

  /// No description provided for @editGuest.
  ///
  /// In en, this message translates to:
  /// **'Edit guest'**
  String get editGuest;

  /// No description provided for @checkInGuest.
  ///
  /// In en, this message translates to:
  /// **'Check in guest'**
  String get checkInGuest;

  /// No description provided for @checkInProgress.
  ///
  /// In en, this message translates to:
  /// **'Check in · {entered} of {admits} entered'**
  String checkInProgress(int entered, int admits);

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get tabPayment;

  /// No description provided for @guestProfile.
  ///
  /// In en, this message translates to:
  /// **'Guest profile'**
  String get guestProfile;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get amountPaid;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @copyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumber;

  /// No description provided for @checkInSection.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInSection;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get notCheckedIn;

  /// No description provided for @checkedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at'**
  String get checkedInAt;

  /// No description provided for @contribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get contribution;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @qrCard.
  ///
  /// In en, this message translates to:
  /// **'QR card'**
  String get qrCard;

  /// No description provided for @qrCardMessage.
  ///
  /// In en, this message translates to:
  /// **'QR card message'**
  String get qrCardMessage;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @notSentYet.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get notSentYet;

  /// No description provided for @sentAt.
  ///
  /// In en, this message translates to:
  /// **'Sent at'**
  String get sentAt;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentSummary;

  /// No description provided for @balanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Balance remaining'**
  String get balanceRemaining;

  /// No description provided for @percentOfTargetPaid.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of target paid'**
  String percentOfTargetPaid(int percent);

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @statusFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get statusFullyPaid;

  /// No description provided for @statusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get statusPartiallyPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @guestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Guest updated'**
  String get guestUpdated;

  /// No description provided for @updateGuestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update guest'**
  String get updateGuestFailed;

  /// No description provided for @alsoOnCard.
  ///
  /// In en, this message translates to:
  /// **'{phone} is also on {name}\'s card'**
  String alsoOnCard(String phone, String name);

  /// No description provided for @alsoGuestNotMerged.
  ///
  /// In en, this message translates to:
  /// **'{phone} is also the guest {name}, who has entries or payments, so they weren\'t merged'**
  String alsoGuestNotMerged(String phone, String name);

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge {name}?'**
  String mergeTitle(String name);

  /// No description provided for @mergeBody.
  ///
  /// In en, this message translates to:
  /// **'{phone} is already {name}, a guest with their own card, so they would get two invitations. Merge them into this card as a companion?'**
  String mergeBody(String phone, String name);

  /// No description provided for @keepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get keepBoth;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @companions.
  ///
  /// In en, this message translates to:
  /// **'Companions'**
  String get companions;

  /// No description provided for @companionsHint.
  ///
  /// In en, this message translates to:
  /// **'Others sharing this card. Anyone with a phone gets the same invitation.'**
  String get companionsHint;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @removeCompanion.
  ///
  /// In en, this message translates to:
  /// **'Remove companion'**
  String get removeCompanion;

  /// No description provided for @addCompanion.
  ///
  /// In en, this message translates to:
  /// **'Add companion'**
  String get addCompanion;

  /// No description provided for @contributionCategory.
  ///
  /// In en, this message translates to:
  /// **'Contribution category'**
  String get contributionCategory;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @peopleOnCard.
  ///
  /// In en, this message translates to:
  /// **'People on this card'**
  String get peopleOnCard;

  /// No description provided for @alreadyEntered.
  ///
  /// In en, this message translates to:
  /// **'{count} already entered'**
  String alreadyEntered(int count);

  /// No description provided for @peopleOnCardHint.
  ///
  /// In en, this message translates to:
  /// **'How many people this card lets in'**
  String get peopleOnCardHint;

  /// No description provided for @amountPaidTzs.
  ///
  /// In en, this message translates to:
  /// **'Amount paid (TZS)'**
  String get amountPaidTzs;

  /// No description provided for @pledgeTzs.
  ///
  /// In en, this message translates to:
  /// **'Pledge (TZS, optional)'**
  String get pledgeTzs;

  /// No description provided for @pledgeHelper.
  ///
  /// In en, this message translates to:
  /// **'What this guest has promised to contribute'**
  String get pledgeHelper;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @categoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptional;

  /// No description provided for @selectedCategory.
  ///
  /// In en, this message translates to:
  /// **'Selected category'**
  String get selectedCategory;

  /// No description provided for @enterHowManyPeople.
  ///
  /// In en, this message translates to:
  /// **'Enter how many people'**
  String get enterHowManyPeople;

  /// No description provided for @fromOneTo.
  ///
  /// In en, this message translates to:
  /// **'From 1 to {max}'**
  String fromOneTo(int max);

  /// No description provided for @cantBeFewer.
  ///
  /// In en, this message translates to:
  /// **'{count} already entered, so it can\'t be fewer'**
  String cantBeFewer(int count);

  /// No description provided for @admitPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Admit 1 person} other{Admit {count} people}}'**
  String admitPeople(int count);

  /// No description provided for @continueScanning.
  ///
  /// In en, this message translates to:
  /// **'Continue scanning'**
  String get continueScanning;

  /// No description provided for @cardUnknownNote.
  ///
  /// In en, this message translates to:
  /// **'This card isn\'t in the phone\'s guest list yet, so its places are unknown. Admitting one person. Refresh the guest list when the network is back.'**
  String get cardUnknownNote;

  /// No description provided for @manualCheckInNote.
  ///
  /// In en, this message translates to:
  /// **'Confirm this is the person at the door. This is recorded as a manual check-in.'**
  String get manualCheckInNote;

  /// No description provided for @cardFullyUsed.
  ///
  /// In en, this message translates to:
  /// **'Card fully used'**
  String get cardFullyUsed;

  /// No description provided for @notAdmitted.
  ///
  /// In en, this message translates to:
  /// **'Not admitted'**
  String get notAdmitted;

  /// No description provided for @admitted.
  ///
  /// In en, this message translates to:
  /// **'Admitted'**
  String get admitted;

  /// No description provided for @savedOnPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will sync automatically when the network allows.'**
  String get savedOnPhoneNote;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {count}'**
  String overBy(int count);

  /// No description provided for @noPlacesLeft.
  ///
  /// In en, this message translates to:
  /// **'No places left'**
  String get noPlacesLeft;

  /// No description provided for @placesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place left} other{{count} places left}}'**
  String placesLeft(int count);

  /// No description provided for @enteredOf.
  ///
  /// In en, this message translates to:
  /// **'{entered} of {admits}'**
  String enteredOf(int entered, int admits);

  /// No description provided for @enteredWord.
  ///
  /// In en, this message translates to:
  /// **'entered'**
  String get enteredWord;

  /// No description provided for @firstEntry.
  ///
  /// In en, this message translates to:
  /// **'First entry'**
  String get firstEntry;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// No description provided for @waitingToSyncShort.
  ///
  /// In en, this message translates to:
  /// **'waiting to sync'**
  String get waitingToSyncShort;

  /// No description provided for @peopleEnteringNow.
  ///
  /// In en, this message translates to:
  /// **'People entering now'**
  String get peopleEnteringNow;

  /// No description provided for @oneFewer.
  ///
  /// In en, this message translates to:
  /// **'One fewer'**
  String get oneFewer;

  /// No description provided for @oneMore.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get oneMore;

  /// No description provided for @noCategoryAssigned.
  ///
  /// In en, this message translates to:
  /// **'No category assigned'**
  String get noCategoryAssigned;

  /// No description provided for @invalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQr;

  /// No description provided for @invalidQrBody.
  ///
  /// In en, this message translates to:
  /// **'Could not decrypt this code. Check your event key in Settings.'**
  String get invalidQrBody;

  /// No description provided for @addContribution.
  ///
  /// In en, this message translates to:
  /// **'Add contribution'**
  String get addContribution;

  /// No description provided for @addContributionSelected.
  ///
  /// In en, this message translates to:
  /// **'Add contribution ({count} selected)'**
  String addContributionSelected(int count);

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tabList;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @byCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryTitle;

  /// No description provided for @loadCategoryDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load category data'**
  String get loadCategoryDataFailed;

  /// No description provided for @noContributionsCollected.
  ///
  /// In en, this message translates to:
  /// **'No contributions collected yet'**
  String get noContributionsCollected;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @overTime.
  ///
  /// In en, this message translates to:
  /// **'Over time'**
  String get overTime;

  /// No description provided for @loadContributionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contributions'**
  String get loadContributionsFailed;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get filterUnpaid;

  /// No description provided for @filterPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get filterPartial;

  /// No description provided for @filterFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get filterFull;

  /// No description provided for @noContributionsFound.
  ///
  /// In en, this message translates to:
  /// **'No contributions found'**
  String get noContributionsFound;

  /// No description provided for @noContributionsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter, or set a pledge on a guest to track it here.'**
  String get noContributionsFoundHint;

  /// No description provided for @contributionCategories.
  ///
  /// In en, this message translates to:
  /// **'Contribution categories'**
  String get contributionCategories;

  /// No description provided for @noCategoriesTapPlus.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\nTap + to add Single, Double, Family and so on.'**
  String get noCategoriesTapPlus;

  /// No description provided for @peoplePerCard.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person per card} other{{count} people per card}}'**
  String peoplePerCard(int count);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteCategoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get deleteCategoryFailed;

  /// No description provided for @noGuestsFound.
  ///
  /// In en, this message translates to:
  /// **'No guests found'**
  String get noGuestsFound;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @pickAtLeastOneGuest.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one guest'**
  String get pickAtLeastOneGuest;

  /// No description provided for @enterPledgeOrPaid.
  ///
  /// In en, this message translates to:
  /// **'Enter a pledge, an amount paid, or both'**
  String get enterPledgeOrPaid;

  /// No description provided for @updatedGuests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 guest} other{Updated {count} guests}}'**
  String updatedGuests(int count);

  /// No description provided for @updatedSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Updated {succeeded}, failed for {failed}'**
  String updatedSomeFailed(int succeeded, int failed);

  /// No description provided for @updateContributionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update contribution'**
  String get updateContributionFailed;

  /// No description provided for @searchGuestByName.
  ///
  /// In en, this message translates to:
  /// **'Search guest by name'**
  String get searchGuestByName;

  /// No description provided for @loadGuestsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load guests'**
  String get loadGuestsFailed;

  /// No description provided for @pledgePerGuest.
  ///
  /// In en, this message translates to:
  /// **'Pledge per guest (TZS)'**
  String get pledgePerGuest;

  /// No description provided for @pledgePerGuestHelper.
  ///
  /// In en, this message translates to:
  /// **'What they committed to give'**
  String get pledgePerGuestHelper;

  /// No description provided for @paidPerGuest.
  ///
  /// In en, this message translates to:
  /// **'Paid per guest (TZS)'**
  String get paidPerGuest;

  /// No description provided for @paidPerGuestHelper.
  ///
  /// In en, this message translates to:
  /// **'Money received now'**
  String get paidPerGuestHelper;

  /// No description provided for @saveForGuests.
  ///
  /// In en, this message translates to:
  /// **'Save for {count} guests'**
  String saveForGuests(int count);

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryTitle(String name);

  /// No description provided for @deleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Guests in this category will be left without a category. Their pledges and payments are not affected.'**
  String get deleteCategoryBody;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @loadCategoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories.'**
  String get loadCategoriesFailed;

  /// No description provided for @noCategoriesUsePlus.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Use the + button to create one.'**
  String get noCategoriesUsePlus;

  /// No description provided for @updateExistingCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update existing cards?'**
  String get updateExistingCardsTitle;

  /// No description provided for @updateExistingCardsBody.
  ///
  /// In en, this message translates to:
  /// **'Cards of this type that still admit {from} can change to {to} too. Cards set to another number by hand keep theirs.'**
  String updateExistingCardsBody(int from, int to);

  /// No description provided for @onlyNewCards.
  ///
  /// In en, this message translates to:
  /// **'Only new cards'**
  String get onlyNewCards;

  /// No description provided for @updateCards.
  ///
  /// In en, this message translates to:
  /// **'Update cards'**
  String get updateCards;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name'**
  String get enterCategoryName;

  /// No description provided for @categorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get categorySaved;

  /// No description provided for @categoryUpdatedCards.
  ///
  /// In en, this message translates to:
  /// **'Category updated · {count} cards now admit {people}'**
  String categoryUpdatedCards(int count, int people);

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get categoryUpdated;

  /// No description provided for @saveCategoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save category'**
  String get saveCategoryFailed;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @peoplePerCardLabel.
  ///
  /// In en, this message translates to:
  /// **'People per card'**
  String get peoplePerCardLabel;

  /// No description provided for @peoplePerCardHelper.
  ///
  /// In en, this message translates to:
  /// **'How many people one card of this type lets in, for example 2 for a couple. Each card can still be changed.'**
  String get peoplePerCardHelper;

  /// No description provided for @saveCategory.
  ///
  /// In en, this message translates to:
  /// **'Save category'**
  String get saveCategory;

  /// No description provided for @createMemberFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create member account'**
  String get createMemberFailed;

  /// No description provided for @loadTeamFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load team'**
  String get loadTeamFailed;

  /// No description provided for @nameAndEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and email are required'**
  String get nameAndEmailRequired;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6;

  /// No description provided for @memberCreated.
  ///
  /// In en, this message translates to:
  /// **'Member account created'**
  String get memberCreated;

  /// No description provided for @addKamatiMember.
  ///
  /// In en, this message translates to:
  /// **'Add kamati member'**
  String get addKamatiMember;

  /// No description provided for @addKamatiMemberLead.
  ///
  /// In en, this message translates to:
  /// **'Create an account for a committee member to help monitor your event.'**
  String get addKamatiMemberLead;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creating;

  /// No description provided for @createMember.
  ///
  /// In en, this message translates to:
  /// **'Create member'**
  String get createMember;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String addedOn(String date);

  /// No description provided for @noKamatiMembers.
  ///
  /// In en, this message translates to:
  /// **'No kamati members yet'**
  String get noKamatiMembers;

  /// No description provided for @noKamatiMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add committee members who can help scan guests and monitor your event.'**
  String get noKamatiMembersHint;

  /// No description provided for @scanCard.
  ///
  /// In en, this message translates to:
  /// **'Scan card'**
  String get scanCard;

  /// No description provided for @pickEventToCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Pick an event to start checking guests in.'**
  String get pickEventToCheckIn;

  /// No description provided for @loadGuestListFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the guest list'**
  String get loadGuestListFailed;

  /// No description provided for @pullToRetry.
  ///
  /// In en, this message translates to:
  /// **'Pull down to try again.'**
  String get pullToRetry;

  /// No description provided for @noGuestsOnEvent.
  ///
  /// In en, this message translates to:
  /// **'No guests on this event yet'**
  String get noGuestsOnEvent;

  /// No description provided for @noGuestListOnPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone doesn\'t have the guest list yet'**
  String get noGuestListOnPhone;

  /// No description provided for @noGuestsOnEventHint.
  ///
  /// In en, this message translates to:
  /// **'Guests added in the portal or on the Guests tab show up here.'**
  String get noGuestsOnEventHint;

  /// No description provided for @noGuestListOnPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet once to download it. Scanning still works offline.'**
  String get noGuestListOnPhoneHint;

  /// No description provided for @tabArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get tabArrived;

  /// No description provided for @tabStillToCome.
  ///
  /// In en, this message translates to:
  /// **'Still to come'**
  String get tabStillToCome;

  /// No description provided for @peopleIn.
  ///
  /// In en, this message translates to:
  /// **'People in'**
  String get peopleIn;

  /// No description provided for @cardsUsed.
  ///
  /// In en, this message translates to:
  /// **'Cards used'**
  String get cardsUsed;

  /// No description provided for @partlyIn.
  ///
  /// In en, this message translates to:
  /// **'Partly in'**
  String get partlyIn;

  /// No description provided for @waitingSyncPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person admitted on this phone is waiting to sync} other{{count} people admitted on this phone are waiting to sync}}'**
  String waitingSyncPeople(int count);

  /// No description provided for @byCardType.
  ///
  /// In en, this message translates to:
  /// **'By card type'**
  String get byCardType;

  /// No description provided for @everyoneIsIn.
  ///
  /// In en, this message translates to:
  /// **'Everyone is in'**
  String get everyoneIsIn;

  /// No description provided for @categoryProgress.
  ///
  /// In en, this message translates to:
  /// **'{toCome} still to come, {arrived} of {cards} cards used'**
  String categoryProgress(int toCome, int arrived, int cards);

  /// No description provided for @filterArrived.
  ///
  /// In en, this message translates to:
  /// **'Filter guests who arrived'**
  String get filterArrived;

  /// No description provided for @filterToCome.
  ///
  /// In en, this message translates to:
  /// **'Filter guests still to come'**
  String get filterToCome;

  /// No description provided for @allCardTypes.
  ///
  /// In en, this message translates to:
  /// **'All card types'**
  String get allCardTypes;

  /// No description provided for @cardTypeCards.
  ///
  /// In en, this message translates to:
  /// **'{type} cards'**
  String cardTypeCards(String type);

  /// No description provided for @showAllCardTypes.
  ///
  /// In en, this message translates to:
  /// **'Show all card types'**
  String get showAllCardTypes;

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchByNameOrPhone;

  /// No description provided for @filterByCardType.
  ///
  /// In en, this message translates to:
  /// **'Filter by card type'**
  String get filterByCardType;

  /// No description provided for @cardType.
  ///
  /// In en, this message translates to:
  /// **'Card type'**
  String get cardType;

  /// No description provided for @typeAtTime.
  ///
  /// In en, this message translates to:
  /// **'{type}, {time}'**
  String typeAtTime(String type, String time);

  /// No description provided for @typePartlyIn.
  ///
  /// In en, this message translates to:
  /// **'{type}, {entered} of {admits} in'**
  String typePartlyIn(String type, int entered, int admits);

  /// No description provided for @waitingSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Admitted on this phone, waiting to sync'**
  String get waitingSyncTooltip;

  /// No description provided for @placesLeftShort.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String placesLeftShort(int count);

  /// No description provided for @enteredShort.
  ///
  /// In en, this message translates to:
  /// **'{entered}/{admits} in'**
  String enteredShort(int entered, int admits);

  /// No description provided for @noSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No guests match your search'**
  String get noSearchMatch;

  /// No description provided for @noSearchMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or clear it.'**
  String get noSearchMatchHint;

  /// No description provided for @noOneInYet.
  ///
  /// In en, this message translates to:
  /// **'No one is in yet'**
  String get noOneInYet;

  /// No description provided for @noOneOfTypeInYet.
  ///
  /// In en, this message translates to:
  /// **'No one with a {type} card is in yet'**
  String noOneOfTypeInYet(String type);

  /// No description provided for @tapScanWhenArrives.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan card when the first guest arrives.'**
  String get tapScanWhenArrives;

  /// No description provided for @everyTypeIn.
  ///
  /// In en, this message translates to:
  /// **'Every {type} card is in'**
  String everyTypeIn(String type);

  /// No description provided for @noPlacesToFill.
  ///
  /// In en, this message translates to:
  /// **'No places left to fill.'**
  String get noPlacesToFill;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @noCardType.
  ///
  /// In en, this message translates to:
  /// **'No card type'**
  String get noCardType;

  /// No description provided for @backToDoor.
  ///
  /// In en, this message translates to:
  /// **'Back to the door overview'**
  String get backToDoor;

  /// No description provided for @keepsScanning.
  ///
  /// In en, this message translates to:
  /// **'Keeps scanning after each guest'**
  String get keepsScanning;

  /// No description provided for @peopleInOf.
  ///
  /// In en, this message translates to:
  /// **'{peopleIn} of {expected} people in'**
  String peopleInOf(int peopleIn, int expected);

  /// No description provided for @flashlightOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off flashlight'**
  String get flashlightOff;

  /// No description provided for @flashlightOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on flashlight'**
  String get flashlightOn;

  /// No description provided for @checkingCard.
  ///
  /// In en, this message translates to:
  /// **'Checking card…'**
  String get checkingCard;

  /// No description provided for @alignQr.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code inside the frame. Pinch to zoom.'**
  String get alignQr;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @alreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Already checked in'**
  String get alreadyCheckedIn;

  /// No description provided for @serverRefusedCheckIn.
  ///
  /// In en, this message translates to:
  /// **'The server refused this check-in'**
  String get serverRefusedCheckIn;

  /// No description provided for @addGuestManually.
  ///
  /// In en, this message translates to:
  /// **'Add guest manually'**
  String get addGuestManually;

  /// No description provided for @importFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get importFromContacts;

  /// No description provided for @offlineLocalGuests.
  ///
  /// In en, this message translates to:
  /// **'Offline · showing locally scanned guests only'**
  String get offlineLocalGuests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noGuestsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or tap + to add a guest.'**
  String get noGuestsFoundHint;

  /// No description provided for @loadGuestsFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load guests'**
  String get loadGuestsFailedTitle;

  /// No description provided for @guestAdded.
  ///
  /// In en, this message translates to:
  /// **'Guest added'**
  String get guestAdded;

  /// No description provided for @addGuestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add guest. Please try again.'**
  String get addGuestFailed;

  /// No description provided for @addGuest.
  ///
  /// In en, this message translates to:
  /// **'Add guest'**
  String get addGuest;

  /// No description provided for @addGuestLead.
  ///
  /// In en, this message translates to:
  /// **'Enter their details by hand instead of picking from contacts.'**
  String get addGuestLead;

  /// No description provided for @leaveEmptyForDefault.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the category\'s {count}'**
  String leaveEmptyForDefault(int count);

  /// No description provided for @contactsPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to import guests.'**
  String get contactsPermissionNeeded;

  /// No description provided for @loadContactsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts.'**
  String get loadContactsFailed;

  /// No description provided for @importNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Import requires an internet connection'**
  String get importNeedsInternet;

  /// No description provided for @importResult.
  ///
  /// In en, this message translates to:
  /// **'{inserted} added, {skipped} skipped'**
  String importResult(int inserted, int skipped);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please try again.'**
  String get importFailed;

  /// No description provided for @importContacts.
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get importContacts;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @contactsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts · {selected} selected'**
  String contactsSelected(int count, int selected);

  /// No description provided for @noContactsWithPhones.
  ///
  /// In en, this message translates to:
  /// **'No contacts with phone numbers found'**
  String get noContactsWithPhones;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @importCount.
  ///
  /// In en, this message translates to:
  /// **'Import ({count})'**
  String importCount(int count);

  /// No description provided for @guestPhoneExists.
  ///
  /// In en, this message translates to:
  /// **'A guest with this phone number already exists'**
  String get guestPhoneExists;

  /// No description provided for @trackMyRequest.
  ///
  /// In en, this message translates to:
  /// **'Track my request'**
  String get trackMyRequest;

  /// No description provided for @requestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent, {name}'**
  String requestSentTo(String name);

  /// No description provided for @requestSpokenTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve spoken with you'**
  String get requestSpokenTitle;

  /// No description provided for @requestSettingUpLead.
  ///
  /// In en, this message translates to:
  /// **'We\'re setting up your event. We\'ll text you when it\'s ready.'**
  String get requestSettingUpLead;

  /// No description provided for @requestReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your event is ready'**
  String get requestReadyTitle;

  /// No description provided for @requestReadyLead.
  ///
  /// In en, this message translates to:
  /// **'Choose a password to open it. You\'ll sign in with {phone}.'**
  String requestReadyLead(String phone);

  /// No description provided for @requestClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request closed'**
  String get requestClosedTitle;

  /// No description provided for @requestClosedLead.
  ///
  /// In en, this message translates to:
  /// **'This request won\'t go ahead. If your plans change, send us a new one.'**
  String get requestClosedLead;

  /// No description provided for @stepReceived.
  ///
  /// In en, this message translates to:
  /// **'We received it'**
  String get stepReceived;

  /// No description provided for @stepWeCall.
  ///
  /// In en, this message translates to:
  /// **'We call you'**
  String get stepWeCall;

  /// No description provided for @stepWeCalled.
  ///
  /// In en, this message translates to:
  /// **'We called you'**
  String get stepWeCalled;

  /// No description provided for @stepCallHint.
  ///
  /// In en, this message translates to:
  /// **'To agree on the details and price'**
  String get stepCallHint;

  /// No description provided for @stepSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up your event'**
  String get stepSettingUp;

  /// No description provided for @stepSetUp.
  ///
  /// In en, this message translates to:
  /// **'Your event is set up'**
  String get stepSetUp;

  /// No description provided for @stepSetUpHint.
  ///
  /// In en, this message translates to:
  /// **'Then you choose your password'**
  String get stepSetUpHint;

  /// No description provided for @choosePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Choose your password'**
  String get choosePasswordButton;

  /// No description provided for @sendNewRequest.
  ///
  /// In en, this message translates to:
  /// **'Send a new request'**
  String get sendNewRequest;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @statusUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String statusUpdatedAt(String time);

  /// No description provided for @statusRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. This is the last status we had.'**
  String get statusRefreshFailed;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @passwordSavedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Password saved. Sign in to open your event.'**
  String get passwordSavedSignIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
