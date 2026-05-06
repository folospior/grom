// PUBLIC CONSTANTS ------------------------------------------------------------

pub const continue = 100

pub const switching_protocols = 101

pub const processing = 102

pub const early_hints = 103

pub const ok = 200

pub const created = 201

pub const accepted = 202

pub const non_authoritative_information = 203

pub const no_content = 204

pub const reset_content = 205

pub const partial_content = 206

pub const multi_status = 207

pub const already_reported = 208

pub const im_used = 226

pub const multiple_choices = 300

pub const moved_permanently = 301

pub const found = 302

pub const see_other = 303

pub const not_modified = 304

pub const use_proxy = 305

pub const temporary_redirect = 307

pub const permanent_redirect = 308

pub const bad_request = 400

pub const unauthorized = 401

pub const payment_required = 402

pub const forbidden = 403

pub const not_found = 404

pub const method_not_allowed = 405

pub const not_acceptable = 406

pub const proxy_authentication_required = 407

pub const request_timeout = 408

pub const conflict = 409

pub const gone = 410

pub const length_required = 411

pub const precondition_failed = 412

pub const content_too_large = 413

pub const uri_too_long = 414

pub const unsupported_media_type = 415

pub const range_not_satisfiable = 416

pub const expectation_failed = 417

pub const im_a_teapot = 418

pub const misdirected_request = 421

pub const unprocessable_content = 422

pub const locked = 423

pub const failed_dependency = 424

pub const too_early = 425

pub const upgrade_required = 426

pub const precondition_required = 428

pub const too_many_requests = 429

pub const request_header_fields_too_large = 431

pub const unavailable_for_legal_reasons = 451

pub const internal_server_error = 500

pub const not_implemented = 501

pub const bad_gateway = 502

pub const service_unavailable = 503

pub const gateway_timeout = 504

pub const http_version_not_supported = 505

pub const variant_also_negotiates = 506

pub const insufficient_storage = 507

pub const loop_detected = 508

pub const not_extended = 510

pub const network_authentication_required = 511

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn is_informational(status: Int) -> Bool {
  status >= 100 && status <= 199
}

pub fn is_successful(status: Int) -> Bool {
  status >= 200 && status <= 299
}

pub fn is_redirection(status: Int) -> Bool {
  status >= 300 && status <= 399
}

pub fn is_client_error(status: Int) -> Bool {
  status >= 400 && status <= 499
}

pub fn is_server_error(status: Int) -> Bool {
  status >= 500 && status <= 599
}
