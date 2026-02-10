import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:provider/provider.dart';
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

  late Map<int, bool> _expandedClients;

  @override
  void initState() {
    super.initState();
    _expandedClients = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatPro = Provider.of<ChatPro>(context, listen: false);
      chatPro.fetchTwilioNumbers();
      chatPro.fetchTwilioClientsWithContacts();
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

  @override
  Widget build(BuildContext context) {
    final chatPro = Provider.of<ChatPro>(context);
    final twilioCredentials = chatPro.twilioNumbers;
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
                onTap: () {},
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
                                onTap: () {
                                  setState(() {
                                    credential.selectedClientId = null;
                                    credential.selectedContactIds = [];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
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
                                      Icon(
                                        Icons.close,
                                        size: 12.sp,
                                        color: Colors.green.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Contact chips
                            ...selectedContacts.map((contact) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    credential.selectedContactIds.removeWhere(
                                      (id) => id == contact.id,
                                    );
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
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
                                      Icon(
                                        Icons.close,
                                        size: 12.sp,
                                        color: Colors.green.shade600,
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

  Widget _buildSelectedChip({
    required String label,
    required String? avatar,
    required String initials,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 12.w,
            backgroundColor: const Color(0xFF00BCD4),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? TextWidget(
                    text: initials,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                : null,
          ),
          Spacers.sbw5(),
          TextWidget(
            text: label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          Spacers.sbw5(),
          GestureDetector(
            onTap: onDelete,
            child: ImageWidget(image: Paths.delete, width: 14),
          ),
        ],
      ),
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
          // Client avatar
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
          // Client name
          Expanded(
            child: TextWidget(
              text: client.name,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          // Expand/collapse icon
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
          CircleAvatar(
            radius: 12.w,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: contact.image != null && contact.image!.isNotEmpty
                ? NetworkImage(contact.image!)
                : null,
            child: contact.image == null || contact.image!.isEmpty
                ? TextWidget(
                    text: contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : 'U',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  )
                : null,
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
                        return _buildAccountBadge(account);
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
          ...credential.assignedAccounts.map((account) {
            return PopupMenuItem<AssignedAccount>(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              child: SizedBox(
                width: double.infinity,
                child: _buildAccountMenuItem(account),
              ),
              onTap: () {
                setState(() {
                  account.isSelected = !account.isSelected;
                });
              },
            );
          }),
        ];
      },
    );
  }

  Widget _buildAccountMenuItem(AssignedAccount account) {
    return StatefulBuilder(
      builder: (context, setStateMenu) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: account.isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14.w,
                backgroundColor: const Color(0xFFE0E0E0),
                child: TextWidget(
                  text: account.accountName[0],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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

  Widget _buildAccountBadge(AssignedAccount account) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.green.shade300, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 7.w,
            backgroundColor: const Color(0xFFE0E0E0),
            child: TextWidget(
              text: account.accountName[0],
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacers.sbw2(),
          TextWidget(
            text: account.accountName,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
          Spacers.sbw2(),
          Icon(Icons.person, size: 10.sp, color: Colors.grey.shade700),
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
                            setMenuState(() {
                              if (isClientSelected) {
                                credential.selectedClientId = null;
                                credential.selectedContactIds = <int>[];
                              } else {
                                credential.selectedClientId = client.id;
                                credential.selectedContactIds = <int>[];
                              }
                            });
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
                                setMenuState(() {
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
                              },
                              child: _buildContactListItem(contact, credential),
                            ),
                          );
                        }),
                    ];
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
