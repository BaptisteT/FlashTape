//
//  ConstantUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "ConstantUtils.h"

//#define EMOJI_ARRAY @[@"❤️", @"😂", @"😔", @"😍", @"☺️", @"😎", @"😉", @"💋", @"😊", @"👍", @"😘", @"😡", @"😀", @"👌", @"😬", @"🙈", @"👅", @"🍻", @"😱", @"🙏", @"🐶", @"😜", @"💩", @"💪",@"😈",@"😷",@"😭",@"😤",@"😴",@"😳"]

#define EMOJI_ARRAY @[@"😀",@"😁",@"😂",@"😃",@"😄",@"😅",@"😆",@"😇",@"😈",@"👿",@"😉",@"😊",@"☺️",@"😋",@"😌",@"😍",@"😎",@"😏",@"😐",@"😑",@"😒",@"😓",@"😔",@"😕",@"😖",@"😗",@"😘",@"😙",@"😚",@"😛",@"😜",@"😝",@"😞",@"😟",@"😠",@"😡",@"😢",@"😣",@"😤",@"😥",@"😦",@"😧",@"😨",@"😩",@"😪",@"😫",@"😬",@"😭",@"😮",@"😯",@"😰",@"😱",@"😲",@"😳",@"😴",@"😵",@"😶",@"😷",@"😸",@"😹",@"😺",@"😻",@"😼",@"😽",@"😾",@"😿",@"🙀",@"👣",@"👤",@"👥",@"👦",@"👧",@"👨",@"👩",@"👫",@"👬",@"👭",@"👮",@"👯",@"👰",@"👱",@"👲",@"👳",@"👴",@"👵",@"👶",@"👷",@"👸",@"💂",@"👼",@"🎅",@"👻",@"👹",@"👺",@"💩",@"💀",@"👽",@"👾",@"🙇",@"💁",@"🙅",@"🙆",@"🙋",@"🙎",@"🙍",@"💆",@"💇",@"💏",@"💅",@"👂",@"👀",@"👃",@"👄",@"💋",@"👅",@"👋",@"👍",@"👎",@"☝️",@"👆",@"👇",@"👈",@"👉",@"👌",@"✌️",@"👊",@"✊",@"✋",@"💪",@"👐",@"🙌",@"👏",@"🙏",@"🌱",@"🌲",@"🌳",@"🌴",@"🌵",@"🌷",@"🌸",@"🌹",@"🌺",@"🌻",@"🌼",@"💐",@"🌾",@"🌿",@"🍀",@"🍁",@"🍂",@"🍃",@"🍄",@"🌰",@"🐀",@"🐁",@"🐭",@"🐹",@"🐂",@"🐃",@"🐄",@"🐮",@"🐅",@"🐆",@"🐯",@"🐇",@"🐰",@"🐈",@"🐱",@"🐎",@"🐴",@"🐏",@"🐑",@"🐐",@"🐓",@"🐔",@"🐤",@"🐣",@"🐥",@"🐦",@"🐧",@"🐘",@"🐪",@"🐫",@"🐗",@"🐖",@"🐷",@"🐽",@"🐕",@"🐩",@"🐶",@"🐺",@"🐻",@"🐨",@"🐼",@"🐵",@"🙈",@"🙉",@"🙊",@"🐒",@"🐉",@"🐲",@"🐊",@"🐍",@"🐢",@"🐸",@"🐋",@"🐳",@"🐬",@"🐙",@"🐟",@"🐠",@"🐡",@"🐚",@"🐌",@"🐛",@"🐜",@"🐝",@"🐞",@"🐾",@"⚡️",@"🔥",@"🌙",@"☀️",@"⛅️",@"☁️",@"💧",@"💦",@"☔️",@"💨",@"❄️",@"🌟",@"⭐️",@"🌠",@"🌄",@"🌅",@"🌈",@"🌊",@"🌋",@"🌌",@"🗻",@"🗾",@"🌐",@"🌍",@"🌎",@"🌏",@"🌑",@"🌒",@"🌓",@"🌔",@"🌕",@"🌖",@"🌗",@"🌘",@"🌚",@"🌝",@"🌛",@"🌜",@"🌞",@"🍅",@"🍆",@"🌽",@"🍠",@"🍇",@"🍈",@"🍉",@"🍊",@"🍋",@"🍌",@"🍍",@"🍎",@"🍏",@"🍐",@"🍑",@"🍒",@"🍓",@"🍔",@"🍕",@"🍖",@"🍗",@"🍘",@"🍙",@"🍚",@"🍛",@"🍜",@"🍝",@"🍞",@"🍟",@"🍡",@"🍢",@"🍣",@"🍤",@"🍥",@"🍦",@"🍧",@"🍨",@"🍩",@"🍪",@"🍫",@"🍬",@"🍭",@"🍮",@"🍯",@"🍰",@"🍱",@"🍲",@"🍳",@"🍴",@"🍵",@"☕️",@"🍶",@"🍷",@"🍸",@"🍹",@"🍺",@"🍻",@"🍼",@"🎀",@"🎁",@"🎂",@"🎃",@"🎄",@"🎋",@"🎍",@"🎑",@"🎆",@"🎇",@"🎉",@"🎊",@"🎈",@"💫",@"✨",@"💥",@"🎓",@"👑",@"🎎",@"🎏",@"🎐",@"🎌",@"🏮",@"💍",@"❤️",@"💔",@"💌",@"💕",@"💞",@"💓",@"💗",@"💖",@"💘",@"💝",@"💟",@"💜",@"💛",@"💚",@"💙",@"🏃",@"🚶",@"💃",@"🚣",@"🏊",@"🏄",@"🛀",@"🏂",@"🎿",@"⛄️",@"🚴",@"🚵",@"🏇",@"⛺️",@"🎣",@"⚽️",@"🏀",@"🏈",@"⚾️",@"🎾",@"🏉",@"⛳️",@"🏆",@"🎽",@"🏁",@"🎹",@"🎸",@"🎻",@"🎷",@"🎺",@"🎵",@"🎶",@"🎼",@"🎧",@"🎤",@"🎭",@"🎫",@"🎩",@"🎪",@"🎬",@"🎨",@"🎯",@"🎱",@"🎳",@"🎰",@"🎲",@"🎮",@"🎴",@"🃏",@"🀄️",@"🎠",@"🎡",@"🎢",@"🚃",@"🚞",@"🚂",@"🚋",@"🚝",@"🚄",@"🚅",@"🚆",@"🚇",@"🚈",@"🚉",@"🚊",@"🚌",@"🚍",@"🚎",@"🚐",@"🚑",@"🚒",@"🚓",@"🚔",@"🚨",@"🚕",@"🚖",@"🚗",@"🚘",@"🚙",@"🚚",@"🚛",@"🚜",@"🚲",@"🚏",@"⛽️",@"🚧",@"🚦",@"🚥",@"🚀",@"🚁",@"✈️",@"💺",@"⚓️",@"🚢",@"🚤",@"⛵️",@"🚡",@"🚠",@"🚟",@"🛂",@"🛃",@"🛄",@"🛅",@"💴",@"💶",@"💷",@"💵",@"🗽",@"🗿",@"🌁",@"🗼",@"⛲️",@"🏰",@"🏯",@"🌇",@"🌆",@"🌃",@"🌉",@"🏠",@"🏡",@"🏢",@"🏬",@"🏭",@"🏣",@"🏤",@"🏥",@"🏦",@"🏨",@"🏩",@"💒",@"⛪️",@"🏪",@"🏫",@"🇨🇳",@"🇫🇷",@"🇩🇪",@"🇮🇹",@"🇯🇵",@"🇰🇷",@"🇪🇸",@"🇬🇧",@"🇺🇸",@"⌚️",@"📱",@"📲",@"💻",@"⏰",@"⏳",@"⌛️",@"📷",@"📹",@"🎥",@"📺",@"📻",@"📟",@"📞",@"☎️",@"📠",@"💽",@"💾",@"💿",@"📀",@"📼",@"🔋",@"🔌",@"💡",@"🔦",@"📡",@"💳",@"💸",@"💰",@"💎",@"🌂",@"👝",@"👛",@"👜",@"💼",@"🎒",@"💄",@"👓",@"👒",@"👡",@"👠",@"👢",@"👞",@"👟",@"👙",@"👗",@"👘",@"👚",@"👕",@"👔",@"👖",@"🚪",@"🚿",@"🛁",@"🚽",@"💈",@"💉",@"💊",@"🔬",@"🔭",@"🔮",@"🔧",@"🔪",@"🔩",@"🔨",@"💣",@"🚬",@"🔫",@"🔖",@"📰",@"🔑",@"✉️",@"📩",@"📨",@"📧",@"📥",@"📤",@"📦",@"📯",@"📮",@"📪",@"📫",@"📬",@"📭",@"📄",@"📃",@"📑",@"📈",@"📉",@"📊",@"📅",@"📆",@"🔅",@"🔆",@"📜",@"📋",@"📖",@"📓",@"📔",@"📒",@"📕",@"📗",@"📘",@"📙",@"📚",@"📇",@"🔗",@"📎",@"📌",@"✂️",@"📐",@"📍",@"📏",@"🚩",@"📁",@"📂",@"✒️",@"✏️",@"📝",@"🔏",@"🔐",@"🔒",@"🔓",@"📣",@"📢",@"🔈",@"🔉",@"🔊",@"🔇",@"💤",@"🔔",@"🔕",@"💭",@"💬",@"🚸",@"🔍",@"🔎"]

@implementation ConstantUtils

NSString * getEmojiAtIndex(NSInteger index)
{
    NSArray *emojiArray = EMOJI_ARRAY;
    return emojiArray[MIN(index,emojiArray.count-1)];
}

NSInteger emojiArrayCount() {
    return EMOJI_ARRAY.count;
}

NSArray * getEmojiAtRange(NSRange range)
{
    NSArray *emojiArray = EMOJI_ARRAY;
    if (range.length + range.location > emojiArray.count) {
        range = NSMakeRange(range.location, emojiArray.count - range.location);
    }
    return [emojiArray subarrayWithRange:range];
}

BOOL belongsToEmojiArray(NSString *emoji) {
    return [EMOJI_ARRAY containsObject:emoji];
}

@end
