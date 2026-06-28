"""
To run in unified python, with ipdb for debugging.
TODO: Check for valid path.

uv run \
    --python 3.14 \
    --with ipdb --with pytest \
    pytest tests/test_e2e.py \
        --exe "$(pwd)/transa.sh" \
        --capture=no \
        --exitfirst
"""

import subprocess
import re
from decimal import Decimal
import pytest
from pathlib import Path


valid_banks = {"itau": "Itaú", "brou": "eBROU", "bcu": "Banco Central del Uruguay"}
valid_digits_bank = {"itau": 2, "brou": 2, "bcu": 4}
default_bank = "itau"


def run_program(executable_path, *args):

    result = subprocess.run(
        [executable_path, *args],
        capture_output=True,
        text=True,
    )

    return {
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr,
    }


def validate_bank_and_exchange_from(
    expected_bank_short: str, exchange_line: str
) -> tuple[Decimal, Decimal]:
    """
    Example exchange_line: Itaú compra y venta: 39.10, 41.10
    """

    digits = valid_digits_bank[expected_bank_short]

    bank_pattern = "|".join(re.escape(bank) for bank in valid_banks.values())
    pattern = rf"^(?P<bank>{bank_pattern}) compra y venta: (?P<buy>\d+\.\d{{{digits}}}), (?P<sell>\d+\.\d{{{digits}}})$"

    match = re.fullmatch(pattern, exchange_line)

    assert match, f"Invalid exchange_line: {exchange_line}"

    bank_long = match["bank"]
    assert valid_banks[expected_bank_short] == bank_long, (
        f"Invalid bank in header: {bank_long}"
    )

    buy = Decimal(match["buy"])
    sell = Decimal(match["sell"])

    assert -buy.as_tuple().exponent == digits
    assert -sell.as_tuple().exponent == digits

    return buy, sell


def validate_mean(mean_line: str) -> tuple[Decimal, Decimal, Decimal]:
    pattern = re.compile(
        r"^\("  # Open parentheses
        r"(-?\d+(?:\.\d+)?) \+ "
        r"(-?\d+(?:\.\d+)?)"
        r"\) / 2 = "
        r"(-?\d+(?:\.\d+)?)$"
    )

    match = pattern.fullmatch(mean_line)
    assert match, "Mean expression is malformed."

    m_buy, m_sell, mean = map(Decimal, match.groups())

    # Validate expression
    assert (m_buy + m_sell) / 2 == mean, (
        "Mean calculation differs from provided in script"
    )

    return m_buy, m_sell, mean


def validate_exchange_and_mean(
    expected_bank_short: str, exchange_line: str, mean_line: str
) -> Decimal:

    buy, sell = validate_bank_and_exchange_from(
        expected_bank_short=expected_bank_short, exchange_line=exchange_line
    )

    # Ensure positive values
    assert buy > 0

    # If this fails, I have a business idea for you.
    assert buy <= sell

    # Parse mean line and validate it.
    m_buy, m_sell, mean = validate_mean(mean_line=mean_line)

    # Check for internal consistency
    assert buy == m_buy, "Buy is inconsistent in output. {buy} != {m_buy}"
    assert sell == m_sell, "Sell is inconsistent in output. {sell} != {m_sell}"

    return mean


@pytest.mark.parametrize("bank_short", [None, "itau", "brou", "bcu"])
def test_default_or_bank_only(executable_path: Path, bank_short: str | None):

    if bank_short is None:
        bank_short = default_bank
        args = []  # We want to NOT provide the bank to the executable in this case.
    else:
        args = [bank_short]

    result = run_program(executable_path, *args)

    # Put expectations here. Can refactor later..
    expected_lines = 3

    # No errors
    assert result["stderr"] == ""
    assert result["returncode"] == 0

    # Check expected number of lines
    output = result["stdout"].split("\n")
    assert len(output) == expected_lines, (
        f"Malformed output as {len(output)} lines, but expected {expected_lines}."
    )
    header_str, mean_calculation_str, _ = output

    _ = validate_exchange_and_mean(
        expected_bank_short=bank_short,
        exchange_line=header_str,
        mean_line=mean_calculation_str,
    )

def parse_transa_line(transa_line: str) -> tuple[Decimal, Decimal]:
    # Parse the output and return the usd and uyu from transa.

    digits = 2
    # rf"^(?P<bank>{bank_pattern}) compra y venta: (?P<buy>\d+\.\d{{{digits}}}), (?P<sell>\d+\.\d{{{digits}}})$"
    pattern = rf"^TRANSA: US\$ (?P<transa_usd>\d+\.\d{{{digits}}}) = \$ (?P<transa_uyu>\d+\.\d{{{digits}}})$"

    match = re.fullmatch(pattern, transa_line)

    assert match, f"Invalid transa line: {transa_line}"

    transa_usd = Decimal(match["transa_usd"])
    transa_uyu = Decimal(match["transa_uyu"])

    assert -transa_usd.as_tuple().exponent == digits
    assert -transa_uyu.as_tuple().exponent == digits

    return transa_usd, transa_uyu


@pytest.mark.parametrize(
    "bank_short,input_usd", [
        (bank, input_usd) 
        for input_usd in ['1000', '1500', '1799'] 
        for bank in [None, "itau", "brou", "bcu"]        
    ]
)
def test_bank_and_usd_input(executable_path: Path, bank_short: str | None, input_usd: str):

    args = [input_usd]
    if bank_short is None:
        bank_short = default_bank
        # Not append bank in the default case.        
    else:
        args.append(bank_short)

    # breakpoint()
    result = run_program(executable_path, *args)

    # Put expectations here. Can refactor later..
    expected_lines = 5

    # No errors
    assert result["stderr"] == ""
    assert result["returncode"] == 0

    # Check expected number of lines
    output = result["stdout"].split("\n")
    assert len(output) == expected_lines, (
        f"Malformed output as {len(output)} lines, but expected {expected_lines}."
    )
    header_str, mean_calculation_str, _, transa_line, _ = output

    mean = validate_exchange_and_mean(
        expected_bank_short=bank_short,
        exchange_line=header_str,
        mean_line=mean_calculation_str,
    )

    transa_usd, transa_uyu = parse_transa_line(transa_line=transa_line)
    
    # Ensure transa is correct.
    # TODO: Add tolerance for rounding.
    # E.g. if input is input_usd is 150.555, then transa_usd should be converted to 150.56
    #      and therefore they won't be equal.
    assert transa_usd == Decimal(input_usd), 'USD input differs from transa'

    # Ensure transa value is consistent with mean
    assert round(transa_usd * mean, 2) == transa_uyu, f'Difference: {transa_usd} * {mean} != {transa_uyu}'


@pytest.mark.parametrize(
    "bank_short,input_uyu", [
        (bank, input_uyu) 
        for input_uyu in ['$1000', '$1500', '$1799'] 
        for bank in [None, "itau", "brou", "bcu"]        
    ]
)
def test_bank_and_uyu_input(executable_path: Path, bank_short: str | None, input_uyu: str):

    args = [input_uyu]
    if bank_short is None:
        bank_short = default_bank
        # Not append bank in the default case.        
    else:
        args.append(bank_short)

    # breakpoint()
    result = run_program(executable_path, *args)

    # Put expectations here. Can refactor later..
    expected_lines = 5

    # No errors
    assert result["stderr"] == ""
    assert result["returncode"] == 0

    # Check expected number of lines
    output = result["stdout"].split("\n")
    assert len(output) == expected_lines, (
        f"Malformed output as {len(output)} lines, but expected {expected_lines}."
    )
    header_str, mean_calculation_str, _, transa_line, _ = output

    mean = validate_exchange_and_mean(
        expected_bank_short=bank_short,
        exchange_line=header_str,
        mean_line=mean_calculation_str,
    )

    transa_usd, transa_uyu = parse_transa_line(transa_line=transa_line)
    
    # Ensure transa is correct.
    # TODO: Add tolerance for rounding.
    assert transa_uyu == Decimal(input_uyu.lstrip('$')), 'UYU input differs from transa'

    # Ensure transa value is consistent with mean
    assert transa_usd == round(transa_uyu / mean, 2)

