// Package indonesian provide utiliy related to Indonesian formatting
package indonesian

import (
	"math"
	"strconv"
	"sync"

	"golang.org/x/text/currency"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/number"
)

var _lang language.Tag
var _currencyUnit currency.Unit
var _currencySymbol interface{}
var _scale, _incCents int
var _incFloat float64
var _incFmt string

var once sync.Once

func init() {
	once.Do(func() {
		_lang = language.MustParse("id_ID")
		_currencyUnit, _ = currency.FromTag(_lang)
		_currencySymbol = currency.Symbol(_currencyUnit)
		_scale, _incCents = currency.Cash.Rounding(_currencyUnit) // fractional digits
		_incFloat = math.Pow10(-_scale) * float64(_incCents)
		_incFmt = strconv.FormatFloat(_incFloat, 'f', _scale, 64)
	})
}

// FormatCurrency ..
func FormatCurrency(val float64) string {
	dec := number.Decimal(val, number.Scale(_scale), number.IncrementString(_incFmt))
	p := message.NewPrinter(_lang)
	return p.Sprintf("%3v%v", _currencySymbol, dec)
}
