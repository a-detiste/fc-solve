

// Adapted from http://www.inventpartners.com/javascript_is_int - thanks.
function is_int(input: number): boolean {
    var value:string = "" + input;
    if ((parseFloat(value) == parseInt(value)) && !isNaN(input)) {
        return true;
    } else {
        return false;
    }
}

var _ranks__int_to_str:string = "0A23456789TJQK";
var _ranks__str_to_int = {};
function _perl_range(start: number, end: number): Array<number> {
    var ret: Array<number> = [];

    for (var i = start; i <= end; i++) {
        ret.push(i);
    }

    return ret;
}

_perl_range(1,13).forEach(function (rank) {
    _ranks__str_to_int[_ranks__int_to_str.substring(rank, rank+1)] = rank;
});
var _suits__int_to_str:string = "HCDS";
var _suits__str_to_int = {};
_perl_range(0,3).forEach(function (suit) {
    _suits__str_to_int[_suits__int_to_str.substring(suit, suit+1)] = suit;
});

class Card {
    private rank: number;
    private suit: number;

    constructor(rank: number, suit: number) {
        if (! is_int(rank)) {
            throw "rank is not an integer.";
        }
        if (! is_int(suit)) {
            throw "suit is not an integer.";
        }
        if (rank < 1) {
            throw "rank is too low.";
        }
        if (rank > 13) {
            throw "rank is too high.";
        }
        if (suit < 0) {
            throw "suit is negative.";
        }
        if (suit > 3) {
            throw "suit is too high.";
        }
        this.rank = rank;
        this.suit = suit;
    }

    getRank(): number {
        return this.rank;
    }

    getSuit(): number {
        return this.suit;
    }

    toString(): string {
        return _ranks__int_to_str.substring(this.rank, this.rank+1) + _suits__int_to_str.substring(this.suit, this.suit+1);
    }
}

class Column {
    private cards: Array<Card>;

    constructor(cards: Array<Card>) {
        this.cards = cards;
    }

    getLen(): number {
        return this.cards.length;
    }

    getCard(idx: number) {
        var that = this;
        if (idx < 0) {
            throw "idx is below zero.";
        }
        if (idx >= that.getLen()) {
            throw "idx exceeds the length of the column.";
        }
        return that.cards[idx];
    }

    getArrOfStrs(): Array<string> {
        var that = this;
        return _perl_range(0, that.getLen()-1).map(function (i) {
            return that.getCard(i).toString();
        });
    }
}



var card_re:string = '([A23456789TJQK])([HCDS])';
export function fcs_js__card_from_string(s: string): Card {
    var m = s.match('^' + card_re + '$');
    if (! m) {
        throw "Invalid format for a card - \"" + s + "\"";
    }
    return new Card(_ranks__str_to_int[m[1]], _suits__str_to_int[m[2]]);
}

class ColumnParseResult {
    public col: Column;
    public is_correct: boolean;
    public start_char_idx: number;
    public num_consumed_chars: number;
    public error: string;

    constructor(is_correct: boolean, start_char_idx: number, num_consumed_chars: number, error: string, cards: Array<Card>) {
        this.is_correct = is_correct;
        this.num_consumed_chars = num_consumed_chars;
        this.error = error;
        this.col = new Column(cards);
        this.start_char_idx = start_char_idx;
    }

    getEnd(): number {
        return (this.start_char_idx + this.num_consumed_chars);
    }
}

class StringParser {
    private s: string;
    private consumed: number;

    constructor(s: string) {
        this.s = s;
        this.consumed = 0;
    }

    consume(m: RegExpMatchArray): void {
        var that = this;
        var len_match:number = m[1].length;
        that.consumed += len_match;
        that.s = that.s.substring(len_match);

        return;
    }

    getConsumed(): number {
        return this.consumed;
    }

    isNotEmpty(): boolean {
        return (this.s.length > 0);
    }

    match(re: any): RegExpMatchArray {
        return this.s.match(re);
    }
}

export function fcs_js__column_from_string(start_char_idx: number, orig_s: string): ColumnParseResult {
    var cards:Array<Card> = [];
    var is_start:boolean = true;

    var p = new StringParser(orig_s);

    p.consume(p.match('^((?:\: +)?)'));
    while (p.isNotEmpty()) {
        var m = p.match(/^(\s*(?:#[^\n]*)?\n?)$/);

        if (m) {
            p.consume(m);
            break;
        }

        m = p.match('^(' + (is_start ? '' : ' +') + '(' + card_re + ')' + ')');
        if (! m) {
            m = p.match('^( *)');
            p.consume(m);

            return new ColumnParseResult(false, start_char_idx, p.getConsumed(), 'Wrong card format - should be [Rank][Suit]', []);
        }

        p.consume(m);
        cards.push(fcs_js__card_from_string(m[2]));
        is_start = false;
    }
    return new ColumnParseResult(true, start_char_idx, p.getConsumed(), '', cards);
}

type MaybeCard = Card | null;

class Freecells {
    private num_freecells: number;
    private cards: Array<MaybeCard>;

    constructor(num_freecells: number, cards: Array<MaybeCard>) {
        if (!is_int(num_freecells)) {
            throw "num_freecells is not an integer.";
        }
        this.num_freecells = num_freecells;

        if (cards.length != num_freecells) {
            throw "cards length mismatch.";
        }
        this.cards = cards;
    }

    getNum(): number {
        return this.num_freecells;
    }

    getCard(idx: number) {
        var that = this;
        if (idx < 0) {
            throw "idx is below zero.";
        }
        if (idx >= that.getNum()) {
            throw "idx exceeds the length of the column.";
        }
        return that.cards[idx];
    }

    getArrOfStrs(): Array<string> {
        var that = this;
        return _perl_range(0, that.getNum()-1).map(function (i) {
            var card = that.getCard(i);
            return ((card !== null) ? card.toString() : '-');
        });
    }
}

// TODO : Merge common functionality with ColumnParseResult into a base class.
class FreecellsParseResult {
    public freecells: Freecells;
    public is_correct: boolean;
    public start_char_idx: number;
    public num_consumed_chars: number;
    public error: string;

    constructor(is_correct: boolean, start_char_idx: number, num_consumed_chars: number, error: string, num_freecells: number, fc: Array<MaybeCard>) {
        this.is_correct = is_correct;
        this.num_consumed_chars = num_consumed_chars;
        this.error = error;
        this.freecells = new Freecells(num_freecells, fc);
        this.start_char_idx = start_char_idx;
    }

    getEnd(): number {
        return (this.start_char_idx + this.num_consumed_chars);
    }
}

export function fcs_js__freecells_from_string(num_freecells: number, start_char_idx: number, s: string): FreecellsParseResult {
    var cards:Array<MaybeCard> = [];
    var is_start:boolean = true;
    var consumed:number = 0;

    function consume_match(m: RegExpMatchArray): void {
        var len_match:number = m[1].length;
        consumed += len_match;
        s = s.substring(len_match);

        return;
    }

    {
        var m = s.match(/^((?:Freecells\: +)?)/);
        if (!m) {
            return new FreecellsParseResult(false, start_char_idx, consumed, 'Wrong ling prefix for freecells - should be "Freecells:"', num_freecells, []);
        }

        consume_match(m);
    }

    while (s.length > 0) {
        var m = s.match(/^(\s*(?:#[^\n]*)?\n?)$/);

        if (m) {
            consume_match(m);
            break;
        }

        m = s.match('^(' + (is_start ? '' : ' +') + "(\\-|(?:" + card_re + '))' + ')');
        if (! m) {
            m = s.match('^( *)');
            consume_match(m);

            return new FreecellsParseResult(false, start_char_idx, consumed, 'Wrong card format - should be [Rank][Suit]', num_freecells, []);
        }

        consume_match(m);
        var card_str = m[2];
        cards.push((card_str == '-') ? null : fcs_js__card_from_string(m[2]));
        is_start = false;
    }

    while (cards.length < num_freecells) {
        cards.push(null);
    }

    if (cards.length != num_freecells) {
        return new FreecellsParseResult(false, start_char_idx, consumed, 'Too many cards specified in Freecells line.', num_freecells, []);
    }

    return new FreecellsParseResult(true, start_char_idx, consumed, '', num_freecells, cards);
}
