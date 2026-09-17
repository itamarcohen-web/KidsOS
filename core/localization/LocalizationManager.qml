pragma Singleton
import QtQuick

// KidsOS localization runtime.
//
// Loads per-language string tables from JSON files at runtime (no
// hard-coded UI strings anywhere in the apps). Exposes:
//   Localization.tr("onboarding.welcome.cta")   -> localized string
//   Localization.tr("onboarding.name.greeting", [name]) -> %1 substitution
//   Localization.language / Localization.isRTL / Localization.setLanguage(code)
//
// String tables live under core/localization/strings/<code>.json and are
// installed to /usr/share/kidsos/locales/<code>.json by the BlueBuild recipe
// (see recipes/recipe.yml). `localesPath` can be overridden for local
// development so the apps run straight out of the source tree.
QtObject {
    id: root

    property string localesPath: "file:///usr/share/kidsos/locales/"
    property string language: "en"
    property var _table: ({})
    property var _fallback: ({})

    readonly property var supportedLanguages: [
        { code: "en", nativeName: "English", direction: "ltr" },
        { code: "he", nativeName: "עברית", direction: "rtl" },
        { code: "ar", nativeName: "العربية", direction: "rtl" }
    ]

    readonly property bool isRTL: language === "he" || language === "ar"
    readonly property int layoutDirection: isRTL ? Qt.RightToLeft : Qt.LeftToRight

    signal languageChanged(string code)

    function _load(code, isPrimary) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", localesPath + code + ".json")
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status !== 200 && xhr.status !== 0) {
                console.warn("Localization: failed to load", code, xhr.status)
                return
            }
            try {
                var parsed = JSON.parse(xhr.responseText)
                if (isPrimary) {
                    root._table = parsed
                    root.languageChanged(code)
                } else {
                    root._fallback = parsed
                }
            } catch (e) {
                console.warn("Localization: malformed JSON for", code, e)
            }
        }
        xhr.send()
    }

    function setLanguage(code) {
        if (!supportedLanguages.some(function (l) { return l.code === code }))
            code = "en"
        language = code
        _load(code, true)
    }

    function _lookup(table, path) {
        var parts = path.split(".")
        var node = table
        for (var i = 0; i < parts.length; i++) {
            if (node === undefined || node === null)
                return undefined
            node = node[parts[i]]
        }
        return typeof node === "string" ? node : undefined
    }

    // tr("a.b.c", ["Daniel"]) — %1, %2… placeholders are substituted in order.
    function tr(key, args) {
        var value = _lookup(_table, key)
        if (value === undefined)
            value = _lookup(_fallback, key)
        if (value === undefined)
            return key
        if (args) {
            for (var i = 0; i < args.length; i++)
                value = value.replace("%" + (i + 1), args[i])
        }
        return value
    }

    Component.onCompleted: {
        // Lets `main.cpp` point this at the source tree for local
        // development (KIDSOS_DEV_LOCALES_PATH env var) instead of the
        // installed /usr/share/kidsos/locales/ path.
        if (typeof KidsOSLocalesPathOverride !== "undefined" && KidsOSLocalesPathOverride.length > 0)
            localesPath = KidsOSLocalesPathOverride
        _load("en", false) // always keep English as the fallback table
        setLanguage(language)
    }
}
