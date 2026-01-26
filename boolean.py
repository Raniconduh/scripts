#!/usr/bin/env python3

import math
from math import log2

literals = [chr(x) for x in range(ord('a'), ord('z'))] + ['1', '0', '-']
n_variables = 0
n_digits = 0

def justifyL(s: str, n: int):
    return s + ' '*(n - len(s))
def justifyR(s: str, n: int):
    return ' '*(n - len(s)) + s

def val_as_bin(val: int, n_variables):
    s = f'{val:b}'
    return '0'*(n_variables - len(s)) + s

def print_primes(s, name):
    print(f'{name} = ' + '{')
    count = 1
    for p in s:
        t = tuple(i for i in p.value)
        print(f'    {p.lits} {t}', end='')
        if p.essential: print(' Essential', end='')
        if count < len(s): print(',')
        else: print()
        count += 1
    print('}')

def print_expression(impl_set, name):
    s = f'{name} = ' + ' + '.join(p.symbolic() for p in impl_set)
    print(s)

class Implicant:
    def __init__(self, lits: str, value: set, prime: bool):
        self.lits = lits
        self.value = value
        self.prime = prime
        self.essential = False

    def covers(minterm: int):
        m = val_as_bin(minterm, len(self.lits))
        for ic, mc in zip(self.lits, m):
            if ic != '-' and ic != mc:
                return False
        return True

    def cost(self):
        count = 0
        for c in self.lits:
            if c != '-': count += 1
        return count

    def symbolic(self):
        exp = ''
        for i in range(len(self.lits)):
            c = self.lits[i]
            if c == '-': continue
            exp += literals[i]
            if c == '0': exp += "'"
        if not exp: return '1'
        return exp

    def __str__(self):
        global n_digits

        p = 'p'
        if not self.prime: p = ' '
        e = ' E'
        if not self.essential: e = ''

        val = '{'
        count = 1
        for i in self.value:
            val += justifyR(str(i), n_digits)
            if count != len(self.value): val += ', '
            count += 1
        val += '}'

        return f'{self.lits} {val} {p}{e}'

    def __repr__(self): return str(self)



class PrintingRows:
    def __init__(self):
        self.rows = ['']

    def add_to(self, row: int, s: str):
        if len(self.rows) < row + 1:
            for i in range(len(self.rows), row + 1): self.rows.append('')
        self.rows[row] += s

    def __str__(self):
        return '\n'.join(self.rows)

    def __repr__(self):
        return str(self)



def distance(a: Implicant, b: Implicant):
    d = 0
    for la, lb in zip(a.lits, b.lits):
        if la != lb: d += 1
    return d

def unite(a: Implicant, b: Implicant):
    lits = ''
    value = a.value.union(b.value)

    for la, lb in zip(a.lits, b.lits):
        if la == lb: lits += la
        else: lits += '-'

    return Implicant(lits, value, None)


class QuineMcCluskey:
    def __init__(self, n_variables: int, minterms: list):
        self.n_variables = n_variables
        self.minterms = minterms
        self.columns = []
        self.primes = []

    def run(self):
        self.columns.append(self.Column(self.n_variables))

        for term in self.minterms:
            self.columns[0].add(Implicant(val_as_bin(term, self.n_variables), {term}, None))

        not_marked = len(self.minterms)
        curr_col = 0
        self.columns.append(self.Column(self.n_variables))
        while not_marked > 0:
            col = self.columns[curr_col]
            for curr_bucket in range(len(col.buckets) - 1):
                bucket = col.buckets[curr_bucket]
                # check every implicant in this bucket with the ones in the next
                for implicant1 in bucket:
                    united = 0
                    for implicant2 in col.buckets[curr_bucket + 1]:
                        if distance(implicant1, implicant2) == 1:
                            u = unite(implicant1, implicant2)
                            if self.columns[curr_col + 1].add(u):
                                not_marked += 1

                            if implicant1.prime is None:
                                implicant1.prime = False
                                not_marked -= 1

                            if implicant2.prime is None:
                                implicant2.prime = False
                                not_marked -= 1

                            united += 1

                    if united == 0 and implicant1.prime is None:
                        implicant1.prime = True
                        self.primes.append(implicant1)
                        not_marked -= 1

            # check the last bucket too
            bucket = col.buckets[-1]
            for impl in bucket:
                if impl.prime is None:
                    impl.prime = True
                    self.primes.append(impl)
                    not_marked -= 1

            curr_col += 1
            if not_marked > 0: self.columns.append(self.Column(self.n_variables))

        return self

    def __str__(self):
        longest_column = 0
        for i in range(len(self.columns)):
            column = self.columns[i]
            if column.length > self.columns[longest_column].length:
                longest_column = i

        rows = PrintingRows()
        # print the whole table:
        for column in self.columns:
            if column.empty(): continue
            curr_row = 0

            for bucket in column.buckets:
                if len(bucket) == 0: continue

                divider = ''
                for i in range(column.max_width + 2):
                    divider += '-'
                divider += '|'

                rows.add_to(curr_row, divider)

                for impl in bucket:
                    curr_row += 1
                    rows.add_to(curr_row, ' ' + justifyL(str(impl), column.max_width) + ' |')

                curr_row += 1

            for i in range(curr_row, self.columns[longest_column].length):
                rows.add_to(curr_row, ' ' * (column.max_width + 2) + '|')
                curr_row += 1

        return str(rows)

    def __repr__(self): return str(self)


    class Column:
        def __init__(self, n_variables):
            self.max_width = 0
            self.length = n_variables
            self.buckets = []

            # generate all buckets
            for _ in range(n_variables + 1):
                self.buckets.append([])

        def add(self, impl: Implicant):
            # ensure implicants with the same value arent added twice
            for bucket in self.buckets:
                for other in bucket:
                    if impl.value == other.value: return False

            n_ones = impl.lits.count('1')
            self.buckets[n_ones].append(impl)

            self.max_width = max(self.max_width, len(str(impl)))
            self.length += 1
            return True

        def empty(self):
            for bucket in self.buckets:
                if len(bucket) > 0: return False
            return True


class ConstraintMatrix:
    def __init__(self, primes, minterms, n_variables, n_digits):
        self.primes = primes
        self.minterms = minterms
        self.n_variables = n_variables
        self.n_digits = n_digits
        self.p_covers = {}

        self.matrix = [
            [ ' ' for _ in range(len(self.minterms)) ] for _ in range(len(self.primes))
        ]

        self.minterm_indices = {
            self.minterms[i]: i for i in range(len(self.minterms))
        }

        for i in range(len(primes)):
            prime = primes[i]
            for minterm in prime.value:
                if minterm not in self.minterms: continue
                j = self.minterm_indices[minterm]
                self.matrix[i][j] = '#'



    def solve_greedy(self):
        sel = []
        P = {pi for pi in self.primes}
        M = {mi for mi in self.minterms}
        Ps = set()

        # find essential primes
        covered = {}
        for p in P:
            for m in p.value:
                if m not in M: continue
                if m not in covered:
                    covered[m] = []
                covered[m].append(p)
        for m, primes in covered.items():
            if len(primes) != 1: continue
            p = primes[0]
            if p not in P: continue

            p.essential = True
            P.remove(p)
            Ps.add(p)
            M = M.difference(p.value)

        while M:
            most_covered = 0
            most_covering = set()
            # find primes with most coverage
            for p in P:
                covering = len(p.value.intersection(M))
                if covering > most_covered:
                    most_covered = covering
                    most_covering.add(p)
            # find the cheapest, highest covering prime
            lowest_cost = self.n_variables + 1
            cheapest = None
            for p in most_covering:
                cost = p.cost()
                if cost < lowest_cost:
                    lowest_cost = cost
                    cheapest = p

            # add p to the solution set, remove its covered minterms
            P.remove(cheapest)
            Ps.add(cheapest)
            M = M.difference(cheapest.value)

        return Ps, sum(p.cost() for p in Ps) + len(Ps)


    def __str__(self):
        rows = PrintingRows()
        widest_minterm = len(str(max(self.minterms)))
        s_minterms = ''
        for minterm in self.minterms:
            s_minterms += ' ' + justifyR(str(minterm), max(2, n_digits)) + ' '
        rows.add_to(0, justifyR(s_minterms, len(s_minterms) + self.n_variables + 1))
        rows.add_to(1, ' ' * (self.n_variables + 1))

        for i in range(1, len(self.primes) + 1):
            prime = self.primes[i - 1]
            rows.add_to(2*i + 1, ' '*(self.n_variables + 1))
            rows.add_to(2*i + 0, justifyR(prime.lits, self.n_variables) + ' ')

        for pi in range(0, len(self.primes)):
            for mi in range(0, len(self.minterms)):
                rows.add_to(2*(pi+1) - 1, '. - ')
                rows.add_to(2*(pi+1) - 0, '| ' + self.matrix[pi][mi] + ' ')

                if mi == len(self.minterms) - 1:
                    rows.add_to(2*(pi+1) - 1, '.')
                    rows.add_to(2*(pi+1) - 0, '|')

            if pi == len(self.primes) - 1:
                for _ in self.minterms:
                    rows.add_to(2*(pi+2) - 1, '. - ')
                rows.add_to(2*(pi+2) - 1, '.')

        return str(rows)

    def __repr__(self): return str(self)


def usage(err=0):
    print('\n'.join((
        "",
        "Usage: boolean",
        " Solves boolean algebra expressions.",
        " First, enter the number of variables. For a function f(a, b, c, d) this is 4.",
        " Then, enter the minterms and don't cares for the cover.",
        " If your on set is {1, 3, 5, 7} and don't care set is {2, 4}, enter: `1 3 5 7 | 2 4`",
        " The on set contains the minterms of your formula.",
        " For `f(a, b, c) = abc + a'bc`, your on set is {0b111, 0b011} = {3, 7}",
        "",
        " The Quine-McCluskey table will be computed and printed along with the",
        "  prime implicants found. The prime implicants will then be run through a",
        "  cover algorithm. The constaint matrix will be printed along with the",
        "  found minimal cover. Any essential prime implicants will be so marked",
        "",
    )))

    quit(err)

def xinput(*args, **kwargs):
    try:
        return input(*args, **kwargs)
    except Exception:
        usage(1)


print("Enter the number of variables (empty or 0 for auto): ", end=None)
n_variables = xinput()
if not n_variables or int(n_variables) == 0: n_variables = 0
else: n_variables = int(n_variables)
if n_variables != 0: n_digits = int(log2(n_variables))

print("Enter `minterms | don't cares`")
inp = xinput()
print("")

implicants = inp.split('|')
minterms = []
dontcares = []

minterms = [int(i) for i in implicants[0].split(' ') if i.isdigit()]
minterms.sort()
if len(implicants) == 2:
    dontcares = [int(i) for i in implicants[1].split(' ') if i.isdigit()]
    dontcares.sort()

implicants = minterms + dontcares
implicants.sort()

if not minterms and not dontcares:
    print("No implicants given")
    usage(1)
elif not set(minterms).isdisjoint(set(dontcares)):
    print("ON set and Don't Care set are not disjoint")
    print("Intersection: ", end="")
    print(set(minterms).intersection(set(dontcares)))
    usage(1)

if n_variables == 0:
    n_variables = math.ceil(log2(implicants[-1]))
    n_digits = int(log2(n_variables))

runner = QuineMcCluskey(n_variables, implicants).run()
primes = runner.primes
print(runner)
print()

print(f'There are {len(primes)} prime implicants:')
print_primes(primes, 'P')


matrix = ConstraintMatrix(primes, minterms, n_variables, n_digits)
print()
print(matrix)


greedy_sol, greedy_cost = matrix.solve_greedy()
print()
print(f'GREEDYCOV solution with {len(greedy_sol)} prime implicants and a cost of {greedy_cost}:')
print_primes(greedy_sol, "Ps")
print("That is, ", end='')
print_expression(greedy_sol, "f")
