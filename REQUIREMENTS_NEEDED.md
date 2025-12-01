# Information Required to Complete AutoLab Students Flutter App

Based on the comprehensive audit, here are the **specific questions and requirements** needed to fully implement the 6 remaining partial features:

---

## 1. CHAT SCREEN - Lab Selection Flow

### Current Issue:
ChatScreen uses placeholder `'default-lab-id'` because it doesn't know which lab to chat in.

### Questions Needed:

**Q1.1:** How should students select which lab to chat in?
- **Option A:** Navigate to chat from a specific lab (e.g., from LabDetailScreen)?
- **Option B:** Show lab selection dialog when opening chat from HomeScreen?
- **Option C:** Allow switching between labs within the chat screen?
- **Option D:** Other approach?

**Q1.2:** If navigating from HomeScreen, should we:
- Show a list of labs first, then open chat for selected lab?
- Or require user to go to Labs → Lab Detail → Chat?

**Q1.3:** Can a student chat in multiple labs simultaneously?
- Should we support multiple chat instances?
- Or one chat at a time?

**Q1.4:** What should happen if student has no labs?
- Show empty state?
- Disable chat tile?

### Required Information:
- [ ] Preferred UX flow for lab selection
- [ ] Whether chat can be accessed directly from HomeScreen
- [ ] Whether multiple lab chats are supported

---

## 2. SPLASH SCREEN - Auth Token Validation

### Current Issue:
SplashScreen always redirects to login, doesn't check if user is already authenticated.

### Questions Needed:

**Q2.1:** Is there a `/auth/me` or `/auth/verify` endpoint to validate tokens?
- Endpoint path: `GET /auth/me`? `POST /auth/verify`? Other?
- Request format: Just Authorization header? Or body with token?
- Response format: UserModel? Just success/fail?

**Q2.2:** Should we validate token on every app start?
- Or just check if token exists in storage?
- What if token exists but is expired?

**Q2.3:** What should happen if token validation fails?
- Clear tokens and go to login?
- Show error message?
- Attempt refresh?

**Q2.4:** Should we show a loading indicator while validating?
- Or just check token existence quickly?

### Required Information:
- [ ] API endpoint for token validation (if exists)
- [ ] Request/response format
- [ ] Error handling strategy
- [ ] Whether to validate or just check existence

---

## 3. AUTH SERVICE - Get Current User

### Current Issue:
`AuthService.getCurrentUser()` returns dummy UserModel instead of fetching from API.

### Questions Needed:

**Q3.1:** What is the API endpoint to get current user?
- Endpoint: `GET /auth/me`? `GET /students/me`? `GET /users/me`? Other?
- Method: GET? POST?

**Q3.2:** What is the response format?
- Does it return full UserModel?
- Or different structure?
- Example response JSON?

**Q3.3:** What headers are required?
- Just Authorization: Bearer token?
- Any other headers?

**Q3.4:** What should happen on error?
- Return null?
- Throw exception?
- Retry logic?

### Required Information:
- [ ] Exact endpoint path
- [ ] HTTP method
- [ ] Request headers
- [ ] Response JSON structure
- [ ] Error response format

---

## 4. GRADES FILTER UI - Lab Selection

### Current Issue:
Provider supports filtering by lab, but no UI component exists.

### Questions Needed:

**Q4.1:** What UI component should be used?
- **Option A:** Dropdown in AppBar
- **Option B:** Filter button/chip that opens bottom sheet
- **Option C:** Segmented control (All / Lab 1 / Lab 2 / ...)
- **Option D:** Other?

**Q4.2:** Should "All Labs" be the default?
- Or show empty state until lab is selected?

**Q4.3:** What labs should appear in the filter?
- All labs the student belongs to?
- Only labs that have grades?
- How to get the list of labs for the filter?

**Q4.4:** Should the filter persist?
- Remember last selected lab?
- Or reset to "All" each time?

**Q4.5:** What if student has no labs?
- Show empty state?
- Disable filter?

### Required Information:
- [ ] Preferred UI component type
- [ ] Default filter state (All vs. specific lab)
- [ ] How to get list of labs for filter dropdown
- [ ] Whether to persist filter selection

---

## 5. FORM VALIDATION - Rules & Messages

### Current Issue:
Login and Register screens have no input validators.

### Questions Needed:

**Q5.1:** Email Validation:
- What format is required? (Standard email regex?)
- Minimum/maximum length?
- Error message text? (English and Arabic)

**Q5.2:** Password Validation:
- Minimum length? (e.g., 6, 8, 12 characters?)
- Maximum length?
- Required characters? (uppercase, lowercase, numbers, symbols?)
- Error message text? (English and Arabic)

**Q5.3:** Name Validation:
- Minimum length? (e.g., 2 characters?)
- Maximum length?
- Allowed characters? (letters only? spaces? special chars?)
- Error message text? (English and Arabic)

**Q5.4:** When should validation occur?
- On field blur (when user leaves field)?
- On form submit?
- Real-time as user types?

**Q5.5:** Should we show validation errors:
- Below each field?
- In a snackbar?
- Both?

### Required Information:
- [ ] Email validation rules (regex, length)
- [ ] Password validation rules (length, complexity)
- [ ] Name validation rules (length, format)
- [ ] Error message translations (en/ar)
- [ ] Validation trigger timing
- [ ] Error display method

---

## 6. LABS LIST SCREEN - Auto-Load Behavior

### Current Issue:
Screen doesn't automatically load labs when first opened.

### Questions Needed:

**Q6.1:** Should labs load automatically when screen opens?
- **Answer likely: YES** ✅

**Q6.2:** What if loading fails?
- Show error message?
- Show retry button?
- Both?

**Q6.3:** Should we show loading indicator?
- Full screen spinner?
- Or skeleton/placeholder?

**Q6.4:** Should we cache labs?
- Or always fetch fresh data?

### Required Information:
- [ ] Confirm auto-load is desired (likely YES)
- [ ] Error handling preference
- [ ] Loading indicator style

---

## 7. STREAMING STATUS ENDPOINTS (Clarification Needed)

### Current Issue:
Requirement says "Must call start/stop stream status endpoints" but students are viewers only.

### Questions Needed:

**Q7.1:** What does "start/stop stream status endpoints" mean for students?
- **Option A:** Students should periodically poll status? (GET endpoint)
- **Option B:** Students should call a specific status check endpoint?
- **Option C:** Just checking `isStreaming` flag in session is enough?
- **Option D:** Students need to "join" the stream before watching?

**Q7.2:** If polling is required:
- How often? (e.g., every 5 seconds, 10 seconds?)
- Should we use WebSocket for real-time updates instead?
- Or REST polling?

**Q7.3:** Are there specific endpoints students should call?
- `GET /sessions/{id}/stream/status`?
- `POST /sessions/{id}/stream/join`?
- Other?

**Q7.4:** What happens when streaming starts/stops?
- Should UI update automatically?
- Or manual refresh needed?

### Required Information:
- [ ] Clarification of "start/stop stream status endpoints" requirement
- [ ] Specific endpoint paths (if any)
- [ ] Polling frequency (if required)
- [ ] Whether WebSocket updates are available

---

## 8. ADDITIONAL CLARIFICATIONS

### Error Handling

**Q8.1:** How should network errors be displayed?
- Toast/snackbar?
- Dialog?
- Inline in UI?
- Consistent across all screens?

**Q8.2:** What error messages should be shown?
- Generic "Something went wrong"?
- Specific API error messages?
- User-friendly translated messages?

### Localization

**Q8.3:** Are all required translations present?
- Need to verify all error messages have translations
- Need validation error message translations

### Backend API Details

**Q8.4:** Are there any other endpoints we should know about?
- User profile update?
- Password change?
- Other student-specific endpoints?

**Q8.5:** What is the expected response format for errors?
- `{ "error": "message" }`?
- `{ "message": "..." }`?
- HTTP status codes only?

---

## SUMMARY: Information Needed

### Critical (Must Have):

1. ✅ **Chat labId flow** - How students select lab for chat
2. ✅ **Auth validation endpoint** - `/auth/me` or similar, response format
3. ✅ **Form validation rules** - Email, password, name requirements
4. ✅ **Streaming status endpoints** - Clarification of requirement

### Important (Should Have):

5. ✅ **Grades filter UI** - Preferred component and behavior
6. ✅ **Error message translations** - All validation errors in en/ar
7. ✅ **Error handling strategy** - Consistent approach across app

### Nice to Have:

8. ✅ **Loading states** - Preferred indicators
9. ✅ **Caching strategy** - Whether to cache data
10. ✅ **Additional endpoints** - Any other student-specific APIs

---

## NEXT STEPS

1. **Get answers to Critical questions** (1-4)
2. **Implement fixes** based on answers
3. **Test all flows** end-to-end
4. **Add missing translations** for validation errors
5. **Final verification** against requirements

---

**Once these questions are answered, the app can be completed to 100% implementation.**

