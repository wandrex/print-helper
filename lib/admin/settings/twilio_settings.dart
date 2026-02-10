import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:print_helper/widgets/toasts.dart';
import 'package:provider/provider.dart';
import 'package:twilio_voice/twilio_voice.dart';
import '../../constants/colors.dart';
import '../../constants/paths.dart';
import '../../models/twilio_models.dart';
import '../../widgets/loaders.dart';
import '../../widgets/text_widget.dart';
import '../../widgets/spacers.dart';
import '../../admin/chat/provider/chat_pro.dart';

class TwilioCredentials extends StatefulWidget {
  const TwilioCredentials({super.key});

  @override
  State<TwilioCredentials> createState() => _TwilioCredentialsState();
}

class _TwilioCredentialsState extends State<TwilioCredentials> {
  final _phoneSearchController = TextEditingController();
  final _companySearchController = TextEditingController();
  final _contactSearchController = TextEditingController();
  final _accountSearchController = TextEditingController();

  late Map<int, bool> expandedClients;
  bool _didSyncSelections = false;
  bool _didUserModify = false;
  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    expandedClients = {};
    _didSyncSelections = false;
    _didUserModify = false;
    _lastSyncKey = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatPro = Provider.of<ChatPro>(context, listen: false);
      chatPro.fetchTwilioNumbers();
      chatPro.fetchTwilioClientsWithContacts();
      chatPro.fetchTwilioStaff();
    });
  }

  @override
  void dispose() {
    _phoneSearchController.dispose();
    _companySearchController.dispose();
    _contactSearchController.dispose();
    _accountSearchController.dispose();
    super.dispose();
  }

  Future<void> _requestPhoneAccountPermission() async {
    try {
      final result = await TwilioVoice.instance
          .requestReadPhoneNumbersPermission();
      if (result is bool) {
        showToast(
          message: result
              ? "Phone number permission granted"
              : "Phone number permission denied",
        );
      } else {
        showToast(message: "Permission request completed");
      }
    } catch (e) {
      showToast(message: "Permission request failed");
      debugPrint("Phone account permission error: $e");
    }
  }

  Future<void> _registerPhoneAccount() async {
    try {
      await TwilioVoice.instance.registerPhoneAccount();
      showToast(message: "Phone account registered");
    } catch (e) {
      showToast(message: "Phone account registration failed");
      debugPrint("Phone account register error: $e");
    }
  }

  Future<void> _openPhoneAccountSettings() async {
    try {
      await TwilioVoice.instance.openPhoneAccountSettings();
    } catch (e) {
      showToast(message: "Unable to open phone account settings");
      debugPrint("Open phone account settings error: $e");
    }
  }

  Future<void> _checkPhoneAccountEnabled() async {
    try {
      final enabled = await TwilioVoice.instance.isPhoneAccountEnabled();
      showToast(
        message: enabled
            ? "Phone account is enabled"
            : "Phone account is disabled",
      );
    } catch (e) {
      showToast(message: "Unable to check phone account status");
      debugPrint("Phone account status error: $e");
    }
  }

  Future<void> _requestCallPhonePermission() async {
    try {
      final result = await TwilioVoice.instance.requestCallPhonePermission();
      if (result is bool) {
        showToast(
          message: result
              ? "Call phone permission granted"
              : "Call phone permission denied",
        );
      } else {
        showToast(message: "Call phone permission request completed");
      }
    } catch (e) {
      showToast(message: "Call phone permission request failed");
      debugPrint("Call phone permission error: $e");
    }
  }

  Future<void> _requestReadPhoneStatePermission() async {
    try {
      final result = await TwilioVoice.instance
          .requestReadPhoneStatePermission();
      if (result is bool) {
        showToast(
          message: result
              ? "Read phone state permission granted"
              : "Read phone state permission denied",
        );
      } else {
        showToast(message: "Read phone state permission request completed");
      }
    } catch (e) {
      showToast(message: "Read phone state permission request failed");
      debugPrint("Read phone state permission error: $e");
    }
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFFFC400), width: 1.2),
        ),
        child: TextWidget(
          text: label,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatPro = Provider.of<ChatPro>(context);
    final twilioCredentials = chatPro.twilioNumbers;

    final syncKey =
        '${chatPro.twilioNumbersRevision}|${chatPro.twilioClientsRevision}|${chatPro.twilioStaffRevision}';
    if (_lastSyncKey != syncKey) {
      _lastSyncKey = syncKey;
      _didSyncSelections = false;
    }

    // Sync selections once after all data is loaded
    if (!_didSyncSelections &&
        !_didUserModify &&
        !chatPro.isTwilioLoading &&
        !chatPro.twilioHasError &&
        !chatPro.isTwilioClientsLoading &&
        !chatPro.twilioClientsHasError &&
        !chatPro.isTwilioStaffLoading &&
        !chatPro.twilioStaffHasError &&
        twilioCredentials.isNotEmpty) {
      _didSyncSelections = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _syncSelectionsFromApi(chatPro);
        });
      });
    }
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: "Twilio Credentials",
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacers.sbw10(),
              GestureDetector(
                onTap: _openPhoneAccountSettings,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFFFC400),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: TextWidget(
                      text: "View Settings",
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildActionButton(
                label: "Request Phone Permission",
                onTap: _requestPhoneAccountPermission,
              ),
              _buildActionButton(
                label: "Register Phone Account",
                onTap: _registerPhoneAccount,
              ),
              _buildActionButton(
                label: "Check Account Enabled",
                onTap: _checkPhoneAccountEnabled,
              ),
              _buildActionButton(
                label: "Request Call Permission",
                onTap: _requestCallPhonePermission,
              ),
              _buildActionButton(
                label: "Enable Connection Service",
                onTap: _requestReadPhoneStatePermission,
              ),
            ],
          ),
        ),
        // Search Filters - Responsive
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSearchField(
                      controller: _phoneSearchController,
                      hint: "Type phone",
                    ),
                  ),
                  Spacers.sbw8(),
                  Expanded(
                    child: _buildSearchField(
                      controller: _companySearchController,
                      hint: "Company",
                    ),
                  ),
                ],
              ),
              Spacers.sb8(),
              Row(
                children: [
                  Expanded(
                    child: _buildSearchField(
                      controller: _contactSearchController,
                      hint: "Contact",
                    ),
                  ),
                  Spacers.sbw8(),
                  Expanded(
                    child: _buildSearchField(
                      controller: _accountSearchController,
                      hint: "Account",
                    ),
                  ),
                  Spacers.sbw8(),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC400),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.search, size: 18.sp, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cards List
        Expanded(
          child: chatPro.isTwilioLoading
              ? Center(child: showLoader())
              : chatPro.twilioHasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                      Spacers.sb15(),
                      TextWidget(
                        text: 'Failed to load Twilio numbers',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                      Spacers.sb15(),
                      ElevatedButton(
                        onPressed: () => chatPro.fetchTwilioNumbers(),
                        child: const TextWidget(
                          text: 'Retry',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : twilioCredentials.isEmpty
              ? Center(
                  child: TextWidget(
                    text: 'No Twilio numbers available',
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  itemCount: twilioCredentials.length,
                  itemBuilder: (context, index) {
                    return _buildCredentialCard(twilioCredentials[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 10.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
        ),
      ),
    );
  }

  void _syncSelectionsFromApi(ChatPro chatPro) {
    for (final credential in chatPro.twilioNumbers) {
      final dynamic client = credential.client;
      if (credential.selectedClientId == null && client is Map) {
        credential.selectedClientId = client['id'] as int?;
      }

      if (credential.selectedContactIds.isEmpty &&
          credential.assignedClients.isNotEmpty) {
        credential.selectedContactIds = credential.assignedClients
            .map((contact) => contact.id)
            .toList();
      }

      if (credential.assignedAccounts.isNotEmpty) {
        credential.assignedAccounts = credential.assignedAccounts
            .map((account) => account.copyWith(isSelected: true))
            .toList();
      }
    }
  }

  Future<void> _saveTwilioAssignments(TwilioCredential credential) async {
    _didUserModify = true;
    final chatPro = Provider.of<ChatPro>(context, listen: false);
    final accountIds = credential.assignedAccounts.map((a) => a.id).toList();
    await chatPro.updateTwilioNumberAssignments(
      numberId: credential.id,
      clientId: credential.selectedClientId,
      contactIds: credential.selectedContactIds,
      accountIds: accountIds,
    );
  }

  Widget _buildCredentialCard(TwilioCredential credential) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Number: ",
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    Spacers.sbw5(),
                    TextWidget(
                      text: credential.phoneNumber,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clients Section
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Assigned Client's Contact",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                Spacers.sb8(),
                _buildClientDropdown(credential),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Accounts Section
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Assigned Account",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                Spacers.sb8(),
                _buildAccountDropdown(credential),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDropdown(TwilioCredential credential) {
    final chatPro = Provider.of<ChatPro>(context);
    // Get selected client and contacts for THIS credential only
    final selectedClient = credential.selectedClientId != null
        ? chatPro.twilioClients.firstWhere(
            (c) => c.id == credential.selectedClientId,
            orElse: () => TwilioClient(
              id: -1,
              name: '',
              image: null,
              isCompany: false,
              contacts: [],
            ),
          )
        : null;
    final selectedContacts = selectedClient != null
        ? selectedClient.contacts
              .where(
                (contact) => credential.selectedContactIds.contains(contact.id),
              )
              .toList()
        : [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dropdown button
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(Offset.zero, ancestor: overlay),
                    button.localToGlobal(
                      button.size.bottomRight(Offset.zero),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                _showClientMenu(
                  context: context,
                  position: position,
                  credential: credential,
                  chatPro: chatPro,
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected chips inside the dropdown
                    if (selectedClient != null && selectedClient.id != -1 ||
                        selectedContacts.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: [
                            // Client chip
                            if (selectedClient != null &&
                                selectedClient.id != -1)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    credential.selectedClientId = null;
                                    credential.selectedContactIds = [];
                                  });
                                  _saveTwilioAssignments(credential);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: const Color(0xFFFFC400),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10.w,
                                        backgroundColor: const Color(
                                          0xFF00BCD4,
                                        ),
                                        backgroundImage:
                                            selectedClient.image != null &&
                                                selectedClient.image!.isNotEmpty
                                            ? NetworkImage(
                                                selectedClient.image!,
                                              )
                                            : null,
                                        child:
                                            selectedClient.image == null ||
                                                selectedClient.image!.isEmpty
                                            ? TextWidget(
                                                text:
                                                    selectedClient
                                                        .name
                                                        .isNotEmpty
                                                    ? selectedClient.name[0]
                                                          .toUpperCase()
                                                    : 'C',
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      Spacers.sbw5(),
                                      TextWidget(
                                        text: selectedClient.name,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      Spacers.sbw5(),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            credential.selectedClientId = null;
                                            credential.selectedContactIds = [];
                                          });
                                          _saveTwilioAssignments(credential);
                                        },
                                        child: ImageWidget(
                                          image: Paths.delete,
                                          width: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ...selectedContacts.map((contact) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    credential.selectedContactIds.removeWhere(
                                      (id) => id == contact.id,
                                    );
                                  });
                                  _saveTwilioAssignments(credential);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFd2e28b),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10.w,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage:
                                            contact.image != null &&
                                                contact.image!.isNotEmpty
                                            ? NetworkImage(contact.image!)
                                            : null,
                                        child:
                                            contact.image == null ||
                                                contact.image!.isEmpty
                                            ? TextWidget(
                                                text: contact.name.isNotEmpty
                                                    ? contact.name[0]
                                                          .toUpperCase()
                                                    : 'U',
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              )
                                            : null,
                                      ),
                                      Spacers.sbw5(),
                                      TextWidget(
                                        text: contact.name,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      Spacers.sbw5(),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            credential.selectedContactIds
                                                .removeWhere(
                                                  (id) => id == contact.id,
                                                );
                                          });
                                          _saveTwilioAssignments(credential);
                                        },
                                        child: ImageWidget(
                                          image: Paths.delete,
                                          width: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    // Dropdown label
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text:
                                (selectedClient == null ||
                                        selectedClient.id == -1) &&
                                    selectedContacts.isEmpty
                                ? "Select client(s) & contact(s)"
                                : "Add more clients & contacts",
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        ImageWidget(image: Paths.down, width: 11),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClientListItem(
    TwilioClient client,
    TwilioCredential credential,
  ) {
    final isSelected = credential.selectedClientId == client.id;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14.w,
            backgroundColor: const Color(0xFF00BCD4),
            backgroundImage: client.image != null && client.image!.isNotEmpty
                ? NetworkImage(client.image!)
                : null,
            child: client.image == null || client.image!.isEmpty
                ? TextWidget(
                    text: client.name.isNotEmpty
                        ? client.name[0].toUpperCase()
                        : 'C',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : null,
          ),
          Spacers.sbw10(),
          Expanded(
            child: TextWidget(
              text: client.name,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (client.contacts.isNotEmpty)
            Icon(Icons.expand_more, size: 20.sp, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildContactListItem(
    TwilioContact contact,
    TwilioCredential credential,
  ) {
    final isSelected = credential.selectedContactIds.contains(contact.id);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Contact avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: ImageWidget(
              image: contact.image.toString().isEmpty || contact.image == null
                  ? Paths.user
                  : contact.image.toString(),
              fit: BoxFit.cover,
              width: 28,
              height: 28,
            ),
          ),
          Spacers.sbw10(),
          // Contact name
          Expanded(
            child: TextWidget(
              text: contact.name,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          // Selection indicator
          if (isSelected)
            Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown(TwilioCredential credential) {
    final chatPro = Provider.of<ChatPro>(context, listen: false);
    final selectedAccounts = credential.assignedAccounts
        .where((account) => account.isSelected)
        .toList();
    return PopupMenuButton<AssignedAccount>(
      offset: Offset(0, 45.h),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      constraints: BoxConstraints(maxWidth: 280.w, minWidth: 280.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: selectedAccounts.isNotEmpty
                    ? selectedAccounts.map((account) {
                        return _buildAccountBadge(account, credential);
                      }).toList()
                    : [
                        TextWidget(
                          text: "Select Accounts",
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade400,
                        ),
                      ],
              ),
            ),
            ImageWidget(image: Paths.down, width: 12),
          ],
        ),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<AssignedAccount>(
            enabled: false,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Accounts",
                  hintStyle: TextStyle(fontSize: 10.sp),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 8.h,
                  ),
                  prefixIcon: Icon(Icons.search, size: 26.sp),
                ),
              ),
            ),
          ),
          PopupMenuItem<AssignedAccount>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: chatPro.twilioStaff.map((staff) {
                    final isSelected = credential.assignedAccounts.any(
                      (account) => account.id == staff.id,
                    );
                    final displayAccount = AssignedAccount(
                      id: staff.id,
                      accountName: staff.accountName,
                      image: staff.image,
                      isSelected: isSelected,
                    );
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            credential.assignedAccounts.removeWhere(
                              (account) => account.id == staff.id,
                            );
                          } else {
                            credential.assignedAccounts.add(
                              AssignedAccount(
                                id: staff.id,
                                accountName: staff.accountName,
                                image: staff.image,
                                isSelected: true,
                              ),
                            );
                          }
                        });
                        _saveTwilioAssignments(credential);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildAccountMenuItem(displayAccount),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildAccountMenuItem(AssignedAccount account) {
    return StatefulBuilder(
      builder: (context, setStateMenu) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: account.isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30.r),
                child: ImageWidget(
                  image:
                      account.image.toString().isEmpty || account.image == null
                      ? Paths.user
                      : account.image.toString(),
                  fit: BoxFit.cover,
                  width: 28,
                  height: 28,
                ),
              ),
              Spacers.sbw8(),
              Expanded(
                child: TextWidget(
                  text: account.accountName,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (account.isSelected)
                Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountBadge(
    AssignedAccount account,
    TwilioCredential credential,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFd2e28b),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.green.shade300, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: ImageWidget(
              image: account.image.toString().isEmpty || account.image == null
                  ? Paths.user
                  : account.image.toString(),
              fit: BoxFit.cover,
              width: 28,
              height: 28,
            ),
          ),
          Spacers.sbw5(),
          TextWidget(
            text: account.accountName,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          Spacers.sbw5(),
          GestureDetector(
            onTap: () {
              setState(() {
                credential.assignedAccounts.removeWhere(
                  (acc) => acc.id == account.id,
                );
              });
              _saveTwilioAssignments(credential);
            },
            child: ImageWidget(
              image: Paths.delete,
              width: 13,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientMenu({
    required BuildContext context,
    required RelativeRect position,
    required TwilioCredential credential,
    required ChatPro chatPro,
  }) {
    showMenu<void>(
      context: context,
      position: position,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      constraints: BoxConstraints(
        maxWidth: 320.w,
        minWidth: 320.w,
        maxHeight: 500.h,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SEARCH
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search Client's Company",
                          hintStyle: TextStyle(fontSize: 12.sp),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          prefixIcon: Icon(Icons.search, size: 22.sp),
                        ),
                      ),
                    ),
                  ),
                  // CLIENTS + CONTACTS
                  ...chatPro.twilioClients.expand((client) {
                    final isClientSelected =
                        credential.selectedClientId == client.id;
                    return [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isClientSelected) {
                                credential.selectedClientId = null;
                                credential.selectedContactIds = <int>[];
                              } else {
                                credential.selectedClientId = client.id;
                                credential.selectedContactIds = <int>[];
                              }
                            });
                            setMenuState(() {});
                            _saveTwilioAssignments(credential);
                          },
                          child: _buildClientListItem(client, credential),
                        ),
                      ),

                      if (isClientSelected)
                        ...client.contacts.map((contact) {
                          final isSelected = credential.selectedContactIds
                              .contains(contact.id);

                          return Padding(
                            padding: EdgeInsets.only(
                              left: 30.w,
                              right: 10.w,
                              top: 4.h,
                              bottom: 4.h,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    credential.selectedContactIds = credential
                                        .selectedContactIds
                                        .where((id) => id != contact.id)
                                        .toList();
                                  } else {
                                    credential.selectedContactIds = [
                                      ...credential.selectedContactIds,
                                      contact.id,
                                    ];
                                  }
                                });
                                setMenuState(() {});
                                _saveTwilioAssignments(credential);
                              },
                              child: _buildContactListItem(contact, credential),
                            ),
                          );
                        }),
                    ];
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
