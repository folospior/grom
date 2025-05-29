import flybycord/message/component/action_row.{type ActionRow}
import flybycord/message/component/button.{type Button}
import flybycord/message/component/channel_select.{type ChannelSelect}
import flybycord/message/component/container.{type Container}
import flybycord/message/component/file.{type File}
import flybycord/message/component/media_gallery.{type MediaGallery}
import flybycord/message/component/mentionable_select.{type MentionableSelect}
import flybycord/message/component/role_select.{type RoleSelect}
import flybycord/message/component/section.{type Section}
import flybycord/message/component/separator.{type Separator}
import flybycord/message/component/string_select.{type StringSelect}
import flybycord/message/component/text_display.{type TextDisplay}
import flybycord/message/component/text_input.{type TextInput}
import flybycord/message/component/user_select.{type UserSelect}
import gleam/dynamic/decode
import gleam/option.{None}

// TYPES -----------------------------------------------------------------------

pub type Component {
  ActionRow(ActionRow)
  Button(Button)
  StringSelect(StringSelect)
  TextInput(TextInput)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
  ChannelSelect(ChannelSelect)
  Section(Section)
  TextDisplay(TextDisplay)
  MediaGallery(MediaGallery)
  File(File)
  Separator(Separator)
  Container(Container)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> {
      use action_row <- decode.then(action_row.decoder())
      decode.success(ActionRow(action_row))
    }
    2 -> {
      use button <- decode.then(button.decoder())
      decode.success(Button(button))
    }
    3 -> {
      use string_select <- decode.then(string_select.decoder())
      decode.success(StringSelect(string_select))
    }
    4 -> {
      use text_input <- decode.then(text_input.decoder())
      decode.success(TextInput(text_input))
    }
    5 -> {
      use user_select <- decode.then(user_select.decoder())
      decode.success(UserSelect(user_select))
    }
    6 -> {
      use role_select <- decode.then(role_select.decoder())
      decode.success(RoleSelect(role_select))
    }
    7 -> {
      use mentionable_select <- decode.then(mentionable_select.decoder())
      decode.success(MentionableSelect(mentionable_select))
    }
    8 -> {
      use channel_select <- decode.then(channel_select.decoder())
      decode.success(ChannelSelect(channel_select))
    }
    9 -> {
      use section <- decode.then(section.decoder())
      decode.success(Section(section))
    }
    10 -> {
      use text_display <- decode.then(text_display.decoder())
      decode.success(TextDisplay(text_display))
    }
    12 -> {
      use media_gallery <- decode.then(media_gallery.decoder())
      decode.success(MediaGallery(media_gallery))
    }
    13 -> {
      use file <- decode.then(file.decoder())
      decode.success(File(file))
    }
    14 -> {
      use separator <- decode.then(separator.decoder())
      decode.success(Separator(separator))
    }
    17 -> {
      use container <- decode.then(container.decoder())
      decode.success(Container(container))
    }
    _ -> decode.failure(ActionRow(action_row.ActionRow(None, [])), "Component")
  }
}
