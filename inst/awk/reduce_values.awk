
BEGIN {
    OFS = "\t"
    split(keep_cols, keepArr, ",")
    split(format_cols, formatArr, ",")
    for (i in keepArr) keep[keepArr[i]]
    for (i in formatArr) format[formatArr[i]]
}

function format_number(num,   parts, mantissa, exponent) {
    if (num ~ /[eE]/) {
        split(num, parts, /[eE]/)
        mantissa = parts[1]
        exponent = parts[2]
        return format_mantissa(mantissa, exponent)
    } else if (num ~ /^[0-9]+(\.[0-9]+)?$/) {
        return sprintf("%.3g", num)
    } else {
        return num
    }
}

function format_mantissa(mantissa, exponent, digits) {
    if (mantissa ~ /^[1-9]/) {
        match(mantissa, /([0-9])\.([0-9]{2})/, digits)
        return digits[1] "." digits[2] "e" exponent
    } else {
        sub(/^0\.0*/, "0.", mantissa)
        match(mantissa, /0\.([1-9][0-9]{2})/, digits)
        return "0." digits[1] "e" exponent
    }
}

{
    for (i = 1; i <= NF; i++) {
        if (i in keep) {
            if (i in format && $i ~ /^[0-9.eE+-]+$/) {
                $i = format_number($i)
            }
            printf "%s", $i
            if (i < NF) printf "\t"
        }
    }
    printf "\n"
}