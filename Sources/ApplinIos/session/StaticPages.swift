import Foundation

class StaticPageKeys {
    /// Applin pushes this page when the app has an error.
    /// Include an ErrorDetails widget to display the message.
    static let APPLIN_CLIENT_ERROR = "/applin-app-error"
    /// Applin pushes this page when it starts and fails to load a previously visible page.
    static let APPLIN_PAGE_NOT_LOADED = "/applin-page-not-loaded"
    /// Applin pushes this page when it fails to make an HTTP request to the server.
    static let APPLIN_NETWORK_ERROR = "/applin-network-error"
    /// Applin pushes this page when the server returns a non-200 response.
    static let APPLIN_SERVER_ERROR = "/applin-rpc-error-modal"
    /// Applin pushes this modal when it fails to load the state file.
    /// Show the user a Connect button so they can retry and deal with auto errors.
    static let APPLIN_STATE_LOAD_ERROR = "/applin-state-load-error"
    /// Applin pushes this page when the server returns a user error message.
    /// Include an ErrorDetails widget to display the message.
    static let APPLIN_USER_ERROR = "/applin-user-error"
    /// The default error pages have an "Error Details" button that pushes this page.
    static let ERROR_DETAILS = "/error-details"
    /// The default first-start (legalForm) page has a "Privacy Policy" button that pushes this page.
    static let PRIVACY_POLICY = "/privacy-policy"
    /// The default error pages have a "Server Status" button that pushes this page.
    static let SERVER_STATUS = "/server-status"
    /// The default error pages have a "Support" button that pushes this page.
    static let SUPPORT = "/support"
    /// The default first-start (legalForm) page has a "Terms of Use" button that pushes this page.
    static let TERMS = "/terms"
}

class StaticPages {
    static func applinClientError(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        ModalSpec(
                pageKey: pageKey,
                kind: .alert,
                // TODO: Include error code in title.
                title: "Error",
                text: "Error in app.  Please try again, quit and reopen the app. or update the app.",
                [
                    ModalButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                    ModalButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    ModalButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                    ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                ]
        ).toSpec()
    }

    static func applinNetworkError(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        ModalSpec(
                pageKey: pageKey,
                kind: .alert,
                title: "Connection Problem",
                text: "Could not contact server.  Check your connection and try again.",
                [
                    ModalButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    ModalButtonSpec(text: "Server Status", [.push(StaticPageKeys.SERVER_STATUS)]),
                    ModalButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                    ModalButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                    ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                ]
        ).toSpec()
    }

    static func applinServerError(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        ModalSpec(
                pageKey: pageKey,
                kind: .alert,
                // TODO: Include error code in title.
                title: "Error",
                text: "Problem talking to server.  Please try again or update the app.",
                [
                    ModalButtonSpec(text: "Error Details", [.push(StaticPageKeys.ERROR_DETAILS)]),
                    ModalButtonSpec(text: "Server Status", [.push(StaticPageKeys.SERVER_STATUS)]),
                    ModalButtonSpec(text: "Support", [.push(StaticPageKeys.SUPPORT)]),
                    ModalButtonSpec(text: "Update App", [.launchUrl(config.appstoreUrl())]),
                    ModalButtonSpec(text: "OK", isDefault: true, [.pop]),
                ]
        ).toSpec()
    }

    static func applinStateLoadError(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        ModalSpec(
                pageKey: pageKey,
                kind: .alert,
                title: "Connect to Load App",
                [ModalButtonSpec(text: "Connect", isDefault: true, [.poll, .pop])]
        ).toSpec()
    }

    static func applinUserError(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        ModalSpec(
                pageKey: pageKey,
                kind: .alert,
                title: "Problem",
                text: "${INTERACTIVE_ERROR_DETAILS}",
                [ModalButtonSpec(text: "OK", isDefault: true, [.pop])]
        ).toSpec()
    }

    static func errorDetails(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(pageKey: pageKey, title: "Error Details", ScrollSpec(
                LastErrorTextSpec()
        )).toSpec()
    }

    static func legalForm(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        PlainPageSpec(title: "Legal Form", ColumnSpec([
            ImageSpec(config, url: "asset:///logo.png", aspectRatio: 1.67, disposition: .fit),
            TextSpec("To use this app, you must agree to the Terms of Use and be at least 18 years old."),
            FormSpec([
                NavButtonSpec(text: "Terms of Use", [.push(StaticPageKeys.TERMS)]),
                NavButtonSpec(text: "Privacy Policy", [.push(StaticPageKeys.PRIVACY_POLICY)]),
            ]),
            FormButtonSpec(text: "I Agree and I am 18+ Years Old", [.replaceAll("/")]),
        ])).toSpec()
    }

    static func pageNotLoaded(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Page Not Loaded",
                ColumnSpec([FormButtonSpec(text: "Load Page", [.poll])])
        ).toSpec()
    }

    static func pageNotFound(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(
                pageKey: pageKey,
                title: "Not Found",
                ColumnSpec([TextSpec("Page not found.")])
        ).toSpec()
    }

    static func serverStatus(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(pageKey: pageKey, title: "Server Status", ScrollSpec(
                // TODO: Replace this with a markdown page that loads the status markdown URL.
                TextSpec("Not implemented")
        )).toSpec()
    }

    static func support(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        var buttons: [ModalButtonSpec] = []
        // TODO: Support including error code in urls.
        if let url = config.supportChatUrl {
            buttons.append(ModalButtonSpec(text: "Support Chat", [.launchUrl(url)]))
        }
        if let email = config.supportEmailAddress {
            let url = URL(string: "mailto:\(email)")!
            buttons.append(ModalButtonSpec(text: "Email Support", [.launchUrl(url)]))
        }
        if let tel = config.supportSmsTel {
            let url = URL(string: "sms:\(tel)")!
            buttons.append(ModalButtonSpec(text: "Text Support", [.launchUrl(url)]))
        }
        buttons.append(ModalButtonSpec(text: "OK", isDefault: true, [.pop]))
        return ModalSpec(pageKey: pageKey, kind: .drawer, title: "Support", text: "", buttons).toSpec()
    }

    static func privacyPolicy(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(pageKey: pageKey, title: "Privacy Policy", ScrollSpec(TextSpec(
                """
                PRIVACY POLICY

                Last Updated: 2023-07-01

                We strive to create a culture of respecting our users and one another.  Your privacy is important to us.  The personal data you share with us is primarily used to provide you with the highest quality service and improve your app experience whenever and wherever possible.  To the best of our ability, we strive to keep your data safe and private, and we do not share individualized personal information with third parties for their own direct marketing purposes.  Details outlined below.

                This privacy policy (“Privacy Policy”) describes the information collected by the operators of this app (“we,” “us,” or “our”), how that information may be used, with whom it may be shared, and your choices about such uses and disclosures. By using our website (“Website”), our mobile apps, and/or other services we provide (collectively, “Service”), you agree to the practices set forth in this Privacy Policy. If you do not agree with this policy, then you must not access or use the Service.

                1. INFORMATION WE COLLECT AND HOW WE COLLECT IT:

                Information collected automatically: When you use the Service, we automatically collect and store certain information about your computer or mobile device and your activities. This information includes:

                - Device Information/Specifications. Technical information about your computer or mobile device (e.g., type of device, web browser or operating system, IP address) to analyze trends, administer the site, prevent fraud, track visitor movement in the aggregate, and gather broad demographic information.
                - Length and Extent of Usage. How long and in what manner you used the Service and which services and features you used.
                - Cookies: We use “cookies” to keep track of some types of information while you are visiting the Service or using our services. “Cookies” are very small files placed on your computer, and they allow us to count the number of visitors to our Website and distinguish repeat visitors from new visitors. They also allow us to save user preferences, track user trends, and advertise to you. We use both session and persistent cookies on our Website; session cookies expire at the end of a particular visit to our Website, while persistent cookies (also called stored cookies) remain active until you disable them through your browser settings, or until a pre-set expiration date. We rely on cookies for the proper operation of the Service; therefore if your browser is set to reject all cookies, the Service may not function properly. Users who refuse cookies assume all responsibility for any resulting loss of functionality with respect to the Service.

                2. INFORMATION YOU CHOOSE TO PROVIDE:

                Information You Provide Directly to Us. In addition, when you register with the Service, you must provide certain information. We may also ask you to upload photos for your profile and may collect any information (including location metadata and inferred characterizations or data) contained in these files. You may provide additional information about yourself in order to build your profile. You may also provide “special categories of personal data” under applicable law, such as your race, ethnicity, religion, philosophical or political views, and information relating to your sex life or sexual orientation. By affirmatively providing the Service with this information, you explicitly consent to our use of it for the purpose of fine tuning the Service. Any information that you provide in your profile will be viewable by other Service users.

                Online Survey Data: We may periodically conduct voluntary member surveys. We encourage our members to participate in such surveys because they provide us with important information regarding the improvement of the Service.  In order to improve the application and create a better experience for our users, survey responses will be linked to your name and contact information so we may follow up to possibly get clarification and collect feedback.

                How we use the information:

                Pursuant to the terms of this Privacy Policy, we may use the information we collect from you for the following purposes:

                - facilitate interactions with other Service users;
                - respond to your comments and questions and provide customer service;
                - to tailor and provide communications to you about the Service and related offers, promotions, advertising, news, upcoming events, and other information we think will be of interest to you;
                - monitor and analyze trends, usage and activities;
                - investigate and prevent fraud and other illegal activities;
                - provide, maintain, and improve the Service and our overall business;
                - where we otherwise have a legitimate interest in doing so, for example, direct marketing, research (including marketing research), network and information security, fraud prevention, and enforcing or defending against legal claims; and
                - where you otherwise consent to such use.

                Use for Research. In addition to the uses outlined above, by using the Service, you agree to allow us to anonymously use the information from you and your experiences in research, so that we may continue to improve the Service experience. This research may be published in our blogs or interviews. However, all of your responses will be kept anonymous, and we assure you that no personally identifiable information will be published.

                3. SHARING YOUR INFORMATION

                The information we collect is used to provide and improve the content and the quality of the Service, and without your consent we will not otherwise share your personal information to/with any other parties for commercial purposes, except: (a) to provide the Service, (b) when we have your permission, or (c) or under the following instances:

                Service Providers. We may share your information with our third-party service providers that support various aspects of our business operations (e.g., marketing and analytics providers and security and technology providers).

                Legal Disclosures and Business Transfers. We may disclose any information without notice or consent from you: (a) in response to a legal request, such as a subpoena, court order, or government demand; (b) to investigate or report illegal activity; or (c) to enforce our rights or defend claims. We may also transfer your information to another organization in connection with a merger, financing due diligence, corporate restructuring, sale of any or all of our assets, or in the event of bankruptcy.

                Aggregate Data. We may combine non-PII we collect with additional non-PII collected from other sources for our blog. We also may share aggregated, non-PII with third parties, including advisors, advertisers and investors, for the purpose of conducting general business analysis.

                4. REFERRING YOUR FRIENDS

                We encourage you to refer your friends to the Service by sending us your friends’ contact information. We will keep this information in our database, and enable you to send these friends a one-time message from your device containing your name and inviting them to try the Service. This message will also include instructions on how to opt out and unsubscribe from future invitations. You agree that you will not abuse this feature by entering the contact information of those individuals who would not be interested in the Service.

                5. UPDATING OR REMOVING ACCOUNT INFORMATION

                You may review or edit your profile as you wish, by logging into your Service account using the information supplied during the registration process. If you would like to have us delete your account information, you may do so by deactivating your account first and then permanently deleting your account. Where you have consented to our use of your personal information, you may withdraw your consent at any time. Notwithstanding the foregoing, we may continue to contact you for the purpose of communicating information relating to your request for services, or to respond to any inquiry or request made by you, as applicable. To opt out of receiving messages concerning the Service, you must cease requesting and/or utilizing services from the Service, and cease submitting inquiries to the Service, as applicable.

                6. THIRD PARTY SITES

                The Service may contain links to other websites and services. If you choose to click on a third party link, you will be directed to that third party’s website or service. The fact that we link to a website or service is not an endorsement, authorization or representation of our affiliation with that third party, nor is it an endorsement of their privacy or information security policies or practices. We do not exercise control over third party websites or services. These third parties may place their own cookies or other files on your computer, collect data or solicit personal information from you. Other websites and services follow different rules regarding the use or disclosure of the personal information you submit to them. We encourage you to read the privacy policies or statements of the other websites and services you visit.

                7. RESIDENTS OF CALIFORNIA

                If you are a California resident, you can request a notice disclosing the categories of personal data about you that we have shared with third parties for their direct marketing purposes during the preceding calendar year. Note that we do not currently share any information with third parties for their own direct marketing purposes. To request this notice, please submit your request to the contact information set out below. Please allow 30 days for a response. For your protection and the protection of all of our users, we may ask you to provide proof of identity before we can answer such a request.

                8. AGE RESTRICTION

                We do not target or allow persons under 18 years of age to use the Service, and we do not knowingly collect information from persons under the age of 16. If you are a parent or legal guardian who discovers that your child has provided us with information without your consent, you may contact us at \(config.supportEmailAddress ?? "our email address"), and we will promptly delete such information from our files.

                9. DATA RETENTION

                The Service retains the personal information we receive as described in this Privacy Policy for as long as you use our services or as necessary to fulfill the purpose(s) for which it was collected, provide our services, resolve disputes, establish legal defenses, conduct audits, pursue legitimate business purposes, enforce our agreements, and comply with applicable laws.

                10. SECURING YOUR PERSONAL INFORMATION

                We take steps to ensure that your information is treated securely and in accordance with this Privacy Policy. Unfortunately, the Internet cannot be guaranteed to be 100% secure, and we cannot ensure or warrant the security of any information you provide to us. We do not accept liability for unintentional disclosure.

                By providing personal information to us, you agree that we may communicate with you electronically regarding security, privacy, and administrative issues relating to your use of the Service. If we learn of a security system’s breach, we may attempt to notify you electronically by posting a notice on the Site or sending a text message to you. You may have a legal right to receive this notice in writing.

                11. CHANGES TO THIS PRIVACY POLICY

                We may update this Privacy Policy from time to time. If there are any material changes to this Privacy Policy, the Service will notify you, via the app, or as otherwise required by applicable law. When we post changes to this Privacy Policy, we will revise the “last updated” date at the top of this Privacy Policy. We recommend that you check our Website from time to time to inform yourself of any changes in this Privacy Policy or any of our other policies.

                12. HOW TO CONTACT US

                If you have any questions about our privacy practices, this Privacy Policy, or how to lodge a complaint with the appropriate authority, please contact us by email at \(config.supportEmailAddress ?? "our email address").
                """
        ))).toSpec()
    }

    static func terms(_ config: ApplinConfig, _ pageKey: String) -> PageSpec {
        NavPageSpec(pageKey: pageKey, title: "Terms of Use", ScrollSpec(TextSpec(
                """
                TERMS OF USE

                Last Updated: 2023-07-01

                1. Acceptance of Terms of Use Agreement.

                By using this app, whether through a mobile device, mobile application or computer (collectively, the “Service”) you agree to be bound by (i) these Terms of Use and (ii) our Privacy Policy, each of which is incorporated by reference into this Agreement, (collectively, this “Agreement”). If you do not accept and agree to be bound by all of the terms of this Agreement (including the arbitration provision contained in Section 14), you should not use the Service.

                The operators of this app (“us,” “we,” the “Operators”) may make changes to this Agreement and to the Service from time to time. We may do this for a variety of reasons including to reflect changes in or requirements of the law, new features, or changes in business practices. The most recent version of this Agreement will be posted on the Service under Settings.  You should regularly check for the most recent version. The most recent version is the version that applies. If the changes include material changes that affect your rights or obligations, we will notify you in advance of the changes by reasonable means, which could include notification through the Service or via email or text message. If you continue to use the Service after the changes become effective, then you agree to the revised Agreement. You agree that this Agreement shall supersede any prior agreements (except as specifically stated herein), and shall govern your entire relationship with Operators, including but not limited to events, agreements, and conduct preceding your acceptance of this Agreement.

                2. Eligibility.

                You must be at least 18 years of age to use the Service. By creating using the Service, you represent and warrant that:

                - you can form a binding contract with the Operators,
                - you are not a person who is barred from using the Service under the laws of the United States or any other applicable jurisdiction–meaning that you do not appear on the U.S. Treasury Department’s list of Specially Designated Nationals or face any other similar prohibition, and
                - you will comply with this Agreement and all applicable local, state, national and international laws, rules and regulations.

                3. Your Account.

                In order to use the Service, you may create an Account via manual registration.  For more information regarding the information we collect from you and how we use it, please consult our Privacy Policy.

                You are responsible for maintaining the confidentiality of your login credentials you use to sign up for the app, and you are solely responsible for all activities that occur under those credentials. If you think someone has gained access to your account, please immediately contact us.

                You may not access, tamper with, or use non-public areas of the App or our systems. Certain portions of the App may not be accessible if you have not registered for an Account.

                4. Modifying the Service and Termination.

                The Operators are always striving to improve the Service and bring you additional functionality that you will find engaging and useful. This means we may add new product features or enhancements from time to time as well as remove some features, and if these actions do not materially affect your rights or obligations, we may not provide you with notice before taking them. We may even suspend the Service entirely, without notice.

                You may terminate your account at any time, for any reason.

                The Operators may terminate your account at any time without notice if we believe that you have violated this Agreement. After your account is terminated, this Agreement will terminate, except that the following provisions will still apply to you and the Operators: Section 4, Section 5, and Sections 11 through 18.

                5. Safety; Your Interactions with Other Users.

                Though the Operators strive to encourage a respectful user experience, we are not responsible for the conduct of any user on or off of the Service. You agree to use caution in all interactions with other users, particularly if you decide to communicate off the Service or meet in person. You agree that you will not provide your financial information (for example, your credit card or bank account information), or wire or otherwise send money to other users.

                YOU ARE SOLELY RESPONSIBLE FOR YOUR INTERACTIONS WITH OTHER USERS. YOU UNDERSTAND THAT THE SERVICE DOES NOT CONDUCT CRIMINAL BACKGROUND CHECKS ON ITS USERS OR OTHERWISE INQUIRE INTO THE BACKGROUND OF ITS USERS. THE OPERATORS MAKE NO REPRESENTATIONS OR WARRANTIES AS TO THE CONDUCT OF USERS.

                6. Rights The Operators Grant You.

                The Operators grant you a personal, worldwide, royalty-free, non-assignable, nonexclusive, revocable, and non-sublicensable license to access and use the Service. This license is for the sole purpose of letting you use and enjoy the Service’s benefits as intended by the Operators and permitted by this Agreement. Therefore, you agree not to:

                - use the Service or any content contained in the Service for any commercial purposes without our written consent.
                - copy, modify, transmit, create any derivative works from, make use of, or reproduce in any way any copyrighted material, images, trademarks, trade names, service marks, or other intellectual property, content or proprietary information accessible through the Service without the Operators' prior written consent.
                - express or imply that any statements you make are endorsed by the Operators.
                - use any robot, bot, spider, crawler, scraper, site search/retrieval application, proxy or other manual or automatic device, method or process to access, retrieve, index, “data mine,” or in any way reproduce or circumvent the navigational structure or presentation of the Service or its contents.
                - use the Service in any way that could interfere with, disrupt or negatively affect the Service or the servers or networks connected to the Service.
                - upload viruses or other malicious code or otherwise compromise the security of the Service.
                - forge headers or otherwise manipulate identifiers in order to disguise the origin of any information transmitted to or through the Service.
                - “frame” or “mirror” any part of the Service without the Operators’s prior written authorization.
                - use meta tags or code or other devices containing any reference to the Operators or the Service (or any trademark, trade name, service mark, logo or slogan of the Operators) to direct any person to any other website for any purpose.
                - modify, adapt, sublicense, translate, sell, reverse engineer, decipher, decompile or otherwise disassemble any portion of the Service, or cause others to do so.
                - use or develop any third-party applications that interact with the Service or other users’ Content or information without our written consent.
                - use, access, or publish the Service's application programming interface without our written consent.
                - probe, scan or test the vulnerability of our Service or any system or network.
                - encourage or promote any activity that violates this Agreement.

                The Operators may investigate and take any available legal action in response to illegal and/ or unauthorized uses of the Service, including termination of your account.

                Any software that we provide you may automatically download and install upgrades, updates, or other new features. You may be able to adjust these automatic downloads through your device’s settings.

                7. Rights You Grant the Operators.

                By creating an account, you grant to the Operators a worldwide, transferable, sub-licensable, royalty-free, right and license to host, store, use, copy, display, reproduce, adapt, edit, publish, modify and distribute information you post, upload, display or otherwise make available (collectively, “post”) on the Service or transmit to other users (collectively, “Content”). The Operators’s license to your Content shall be non-exclusive, except that the Operators’s license shall be exclusive with respect to derivative works created through use of the Service. For example, the Operators would have an exclusive license to screenshots of the Service that include your Content. In addition, so that the Operators can prevent the use of your Content outside of the Service, you authorize the Operators to act on your behalf with respect to infringing uses of your Content taken from the Service by other users or third parties. This expressly includes the authority, but not the obligation, to send notices pursuant to 17 U.S.C. § 512(c)(3) (i.e., DMCA Takedown Notices) on your behalf if your Content is taken and used by third parties outside of the Service. Our license to your Content is subject to your rights under applicable law (for example laws regarding personal data protection to the extent any Content contains personal information as defined by those laws) and is for the limited purpose of operating, developing, providing, and improving the Service and researching and developing new ones. You agree that any Content you place or that you authorize us to place on the Service may be viewed by other users and may be viewed by any person visiting or participating in the Service (such as individuals who may receive shared Content from other users of the app).

                You agree that all information that you submit upon creation of your account is accurate and truthful and you have the right to post the Content on the Service and grant the license to the Operators above.

                You understand and agree that we may monitor or review any Content you post as part of a Service. We may delete any Content, in whole or in part, that in our sole judgment violates this Agreement or may harm the reputation of the Service.

                When communicating with our customer care representatives, you agree to be respectful and kind. If we feel that your behavior towards any of our customer care representatives or other employees is at any time threatening or offensive, we reserve the right to immediately terminate your account.

                In consideration for the Operators allowing you to use the Service, you agree that we, our affiliates, and our third-party partners may place advertising on the Service. By submitting suggestions or feedback to the Operators regarding our Service, you agree that the Operators may use and share such feedback for any purpose without compensating you.

                You agree that the Operators may access, preserve and disclose your account information and Content if required to do so by law or in a good faith belief that such access, preservation or disclosure is reasonably necessary, such as to: (i) comply with legal process; (ii) enforce this Agreement; (iii) respond to claims that any Content violates the rights of third parties; (iv) respond to your requests for customer service; or (v) protect the rights, property or personal safety of the Operators or any other person.

                8. Community Rules.

                By using the Service, you agree that you will not:

                - use the Service for any purpose that is illegal or prohibited by this Agreement.
                - use the Service for any harmful or nefarious purpose.
                - use the Service in order to damage the Operators.
                - violate our Community Guidelines, as updated from time to time.
                - spam, solicit money from or defraud any users.
                - impersonate any person or entity or post any images of another person without his or her permission.
                - bully, “stalk,” intimidate, assault, harass, mistreat or defame any person.
                - post any Content that violates or infringes anyone’s rights, including rights of publicity, privacy, copyright, trademark or other intellectual property or contract right.
                - post any Content that is hate speech, threatening, sexually explicit or pornographic; incites violence; or contains nudity or graphic or gratuitous violence.
                - post any Content that promotes racism, bigotry, hatred or physical harm of any kind against any group or individual.
                - solicit passwords for any purpose, or personal identifying information for commercial or unlawful purposes from other users or disseminate another person’s personal information without his or her permission.
                - use another user’s account.
                - create another account if we have already terminated your account, unless you have our permission.

                The Operators reserve the right to investigate and/ or terminate your account if you have violated this Agreement, misused the Service or behaved in a way that the Operators regard as inappropriate or unlawful, including actions or communications that occur on or off the Service.

                9. Other Users’ Content.

                Although the Operators reserve the right to review and remove Content that violates this Agreement, such Content is the sole responsibility of the user who posts it, and the Operators cannot guarantee that all Content will comply with this Agreement. If you see Content on the Service that violates this Agreement, please report it within the Service or via \(config.supportEmailAddress ?? "our company address").

                10. DIGITAL MILLENNIUM COPYRIGHT ACT

                The Operators have adopted the following policy towards copyright infringement in accordance with the Digital Millennium Copyright Act (the "DMCA"). If you believe that your work has been copied and posted on the Service in a way that constitutes copyright infringement, please submit a notification alleging such infringement ("DMCA Takedown Notice") including the following:

                - A physical or electronic signature of a person authorized to act on behalf of the owner of an exclusive right that is allegedly infringed;
                - Identification of the copyrighted work claimed to have been infringed, or, if multiple copyrighted works at a single online site are covered by a single notification, a representative list of such works;
                - Identification of the material claimed to be infringing or to be the subject of infringing activity and that is to be removed or access disabled and information reasonably sufficient to permit the service provider to locate the material;
                - Information reasonably sufficient to permit the service provider to contact you, such as an address, telephone number, and, if available, an electronic mail;
                - A statement that you have a good faith belief that use of the material in the manner complained of is not authorized by the copyright owner, its agent, or the law; and
                - A statement that, under penalty of perjury, the information in the notification is accurate and you are authorized to act on behalf of the owner of the exclusive right that is allegedly infringed.

                Any DMCA Takedown Notices should be sent to: \(config.supportEmailAddress ?? "our email address")

                The Operators will terminate the accounts of repeat infringers.

                11. Disclaimers.

                THE OPERATORS PROVIDE THE SERVICE ON AN “AS IS” AND “AS AVAILABLE” BASIS AND TO THE EXTENT PERMITTED BY APPLICABLE LAW, GRANT NO WARRANTIES OF ANY KIND, WHETHER EXPRESS, IMPLIED, STATUTORY OR OTHERWISE WITH RESPECT TO THE SERVICE (INCLUDING ALL CONTENT CONTAINED THEREIN), INCLUDING, WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF SATISFACTORY QUALITY, MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT. THE OPERATORS DO NOT REPRESENT OR WARRANT THAT (A) THE SERVICE WILL BE UNINTERRUPTED, SECURE OR ERROR FREE, (B) ANY DEFECTS OR ERRORS IN THE SERVICE WILL BE CORRECTED, OR (C) THAT ANY CONTENT OR INFORMATION YOU OBTAIN ON OR THROUGH THE SERVICE WILL BE ACCURATE.

                THE OPERATORS TAKE NO RESPONSIBILITY FOR ANY CONTENT THAT YOU OR ANOTHER USER OR THIRD PARTY POSTS, SENDS OR RECEIVES THROUGH THE SERVICE. ANY MATERIAL DOWNLOADED OR OTHERWISE OBTAINED THROUGH THE USE OF THE SERVICE IS ACCESSED AT YOUR OWN DISCRETION AND RISK.

                THE OPERATORS DISCLAIM AND TAKE NO RESPONSIBILITY FOR ANY CONDUCT OF YOU OR ANY OTHER USER, ON OR OFF THE SERVICE.

                12. Third Party Services.

                The Service may contain advertisements and promotions offered by third parties and links to other web sites or resources. The Operators are not responsible for the availability (or lack of availability) of such external websites or resources. If you choose to interact with the third parties made available through our Service, such party’s terms will govern their relationship with you. The Operators are not responsible or liable for such third parties’ terms or actions.

                13. Limitation of Liability.

                TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL THE OPERATORS, THEIR AFFILIATES, EMPLOYEES, LICENSORS OR SERVICE PROVIDERS BE LIABLE FOR ANY INDIRECT, CONSEQUENTIAL, EXEMPLARY, INCIDENTAL, SPECIAL, PUNITIVE, OR ENHANCED DAMAGES, INCLUDING, WITHOUT LIMITATION, LOSS OF PROFITS, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM: (I) YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE SERVICE; (II) THE CONDUCT OR CONTENT OF OTHER USERS OR THIRD PARTIES ON, THROUGH OR FOLLOWING USE OF THE SERVICE; OR (III) UNAUTHORIZED ACCESS, USE OR ALTERATION OF YOUR CONTENT, EVEN IF THE OPERATORS HAVE BEEN ADVISED AT ANY TIME OF THE POSSIBILITY OF SUCH DAMAGES. NOTWITHSTANDING THE FOREGOING, IN NO EVENT SHALL THE OPERATORS’ AGGREGATE LIABILITY TO YOU FOR ANY AND ALL CLAIMS ARISING OUT OF OR RELATING TO THE SERVICE OR THIS AGREEMENT EXCEED THE AMOUNT PAID, IF ANY, BY YOU TO THE OPERATORS DURING THE TWENTY-FOUR (24) MONTH PERIOD IMMEDIATELY PRECEDING THE DATE THAT YOU FIRST FILE A LAWSUIT, ARBITRATION OR ANY OTHER LEGAL PROCEEDING AGAINST THE OPERATORS, WHETHER IN LAW OR IN EQUITY, IN ANY TRIBUNAL. THE DAMAGES LIMITATION SET FORTH IN THE IMMEDIATELY PRECEDING SENTENCE APPLIES (i) REGARDLESS OF THE GROUND UPON WHICH LIABILITY IS BASED (WHETHER DEFAULT, CONTRACT, TORT, STATUTE, OR OTHERWISE), (ii) IRRESPECTIVE OF THE TYPE OF BREACH OF OBLIGATIONS, AND (iii) WITH RESPECT TO ALL EVENTS, THE SERVICE, AND THIS AGREEMENT.

                THE LIMITATION OF LIABILITY PROVISIONS SET FORTH IN THIS SECTION 13 SHALL APPLY EVEN IF YOUR REMEDIES UNDER THIS AGREEMENT FAIL WITH RESPECT TO THEIR ESSENTIAL PURPOSE.

                SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF CERTAIN DAMAGES, SO SOME OR ALL OF THE EXCLUSIONS AND LIMITATIONS IN THIS SECTION MAY NOT APPLY TO YOU.

                14. Arbitration and Class Action Waiver.

                -- IMPORTANT -- PLEASE REVIEW AS THIS AFFECTS YOUR LEGAL RIGHTS.

                The exclusive means of resolving any dispute or claim arising out of or relating to these Terms of Use (including any alleged breach thereof), the Service, or the Website shall be BINDING ARBITRATION administered by the American Arbitration Association under the Consumer Arbitration Rules. The one exception to the exclusivity of arbitration is that you have the right to bring an individual claim against the Operators in a small-claims court of competent jurisdiction. But whether you choose arbitration or small-claims court, you may not under any circumstances commence or maintain against the Operators any class action, class arbitration, or other representative action or proceeding.

                By using the Website or the Service in any manner, you agree to the above arbitration agreement. In doing so, YOU GIVE UP YOUR RIGHT TO GO TO COURT to assert or defend any claims between you and the Operators (except for matters that may be taken to small-claims court). YOU ALSO GIVE UP YOUR RIGHT TO PARTICIPATE IN A CLASS ACTION OR OTHER CLASS PROCEEDING. Your rights will be determined by a NEUTRAL ARBITRATOR, NOT A JUDGE OR JURY, and the arbitrator shall determine all issues regarding the arbitrability of the dispute. You are entitled to a fair hearing before the arbitrator. The arbitrator can grant any relief that a court can, but you should note that arbitration proceedings are usually simpler and more streamlined than trials and other judicial proceedings. Decisions by the arbitrator are enforceable in court and may be overturned by a court only for very limited reasons.

                Any proceeding to enforce this arbitration agreement, including any proceeding to confirm, modify, or vacate an arbitration award, may be commenced in any court of competent jurisdiction. In the event that this arbitration agreement is for any reason held to be unenforceable, any litigation against the Operators (except for small-claims court actions) may be commenced only in the federal or state courts located in California. You hereby irrevocably consent to the jurisdiction of those courts for such purposes.

                15. Governing Law.

                Except where our arbitration agreement is prohibited by law, the laws of California, U.S.A., without regard to its conflict of laws rules, shall apply to any disputes arising out of or relating to this Agreement, the Service, or your relationship with the Operators. Notwithstanding the foregoing, the Arbitration Agreement in Section 14 above shall be governed by the Federal Arbitration Act.

                16. Venue.

                Except for claims that may be properly brought in a small claims court of competent jurisdiction in the county in which you reside or in California, all claims arising out of or relating to this Agreement, to the Service, or to your relationship with the Operators that for whatever reason are not submitted to arbitration will be litigated exclusively in the federal or state courts of California, U.S.A. You and the Operators consent to the exercise of personal jurisdiction of courts in the State of California and waive any claim that such courts constitute an inconvenient forum.

                17. Indemnity.

                All the actions you make and information you post on the Service remain your responsibility. Therefore, you agree to indemnify, defend, release, and hold us, and our partners, licensors, affiliates, contractors, officers, directors, employees, representatives and agents, harmless, from and against any third party claims, damages (actual and/or consequential), actions, proceedings, demands, losses, liabilities, costs and expenses (including reasonable legal fees) suffered or reasonably incurred by us arising as a result of, or in connection with:

                1. any negligent acts, omissions or wilful misconduct by you;
                2. your access to and use of the Service;
                3. the uploading or submission of Content to the Service by you;
                4. any breach of these Terms by you; and/or
                5. your violation of any law or of any rights of any third party.

                We retain the exclusive right to settle, compromise and pay any and all claims or causes of action which are brought against us without your prior consent. If we ask, you will co-operate fully and reasonably as required by us in the defence of any relevant claim.

                18. Entire Agreement; Other.

                This Agreement, along with the Privacy Policy, the Dating Etiquette Guide, and any terms disclosed to you contains the entire agreement between you and the Operators regarding your relationship with the Operators and the use of the Service. If any provision of this Agreement is held invalid, the remainder of this Agreement shall continue in full force and effect. The failure of the Operators to exercise or enforce any right or provision of this Agreement shall not constitute a waiver of such right or provision. You agree that your account on the Service is non-transferable and all of your rights to your account and its Content terminate upon your death. No agency, partnership, joint venture, fiduciary or other special relationship or employment is created as a result of this Agreement and you may not make any representations on behalf of or bind the Operators in any manner.
                """
        ))).toSpec()
    }
}
