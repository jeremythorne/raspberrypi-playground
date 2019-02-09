"""
A solver for a puzzle cube.

The cube consists of six 4x4 pieces which interlock to form a hollow 4x4x4
cube. This code iterates through possible combinations to find the solution.
"""

class State:
    """ represent the current state of an attempt"""

    def __init__(self, cube, pieces, rotations, working_pieces = None, working_rotations = None):
        self.cube = cube
        self.pieces = pieces
        self.rotations = rotations
        self.choice = None
        if working_pieces == None:
            self.working_pieces = self.pieces[:]
        else:
            self.working_pieces = working_pieces
        if working_rotations == None:
            self.working_rotations = self.rotations[:]
        else:
            self.working_rotations = working_rotations

    def clone(self):
        p = self.pieces[:]
        r = self.rotations[:]
        c = self.cube.clone()
        return State(c, p, r)

    def set(self, ri, pi, fi):
        self.choice = (ri, pi, fi)
        self.rotations = range(4)
        self.pieces.remove(pi)
        self.cube.choose(ri, pi, fi)
        self.working_pieces = self.pieces[:]
        self.working_rotations = self.rotations[:]

    def __str__(self):
        return "choice {}\nrotations {}\npieces {}\ncube {}\nworking pieces {}\nworking_rotations {}".format(
            self.choice,
            self.rotations,
            self.pieces,
            self.cube,
            self.working_pieces,
            self.working_rotations)

    def next(self):
        if len(self.working_rotations) == 0:
            self.working_rotations = range(4)
            self.working_pieces.pop()
        if len(self.working_pieces) == 0:
            return None, None
 
        return self.working_rotations.pop(), self.working_pieces[-1]

def make_faces():
    """return six arrays - one for each face listing the edge indices"""

    return [
            [ 0,  1,  2,  3,  4,  5,  6, 23, 22, 21, 20, 19],
            [ 0, 19, 20, 21, 29, 28, 18, 17, 16, 15, 14, 13],
            [21, 22, 23,  6, 24, 25, 12, 26, 27, 18, 28, 29],
            [ 6,  5,  4,  3,  7,  8,  9, 10, 11, 12, 25, 24],
            [18, 27, 26, 12, 11, 10,  9, 31, 30, 15, 16, 17],
            [15, 30, 31,  9,  8,  7,  3,  2,  1,  0, 13, 14]
    ]

def check_faces(faces):
    """count the number of times an edge index is used in all the faces

    indices should be used 2 times for an edge and 3 times for a corner"""

    counts = [0] * 32
    for face in faces:
        for i in face:
            counts[i] += 1
    #print counts

class Piece:
    """represent one of the six puzzle pieces

    in terms of the occupany of the edge slots and the possible transformations
    thereof by rotating the piece.
    """
    def __init__(self, indices):
        self.indices = indices
        self.make_rotations()

    def make_rotations(self):
        self.rotations = [0] * 4
        for i in range(4):
            self.rotations[i] = [0] * 12
            shift = i * 3
            for j in range(12):
                self.rotations[i][j] = self.indices[(j+shift) % 12]

    def get(self, ri):
        return self.rotations[ri]

def make_pieces():
    """generqte the six pieces"""
    return [
            Piece([0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0]),
            Piece([0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1]),
            Piece([0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1]),
            Piece([0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0]),
            Piece([1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0]),
            Piece([0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0])
    ]

class Cube:
    """represent the 32 edge slots of a 4x4x4 cube"""
    def __init__(self, faces, pieces):
        self.faces = faces
        self.pieces = pieces
        self.set = [0] * 32

    def choose(self, ri, pi, fi):
        """set the edge slots that will be occupied by a given rotation, piece
        and face"""
        face = self.faces[fi]
        rotation = self.pieces[pi].get(ri)

        for i in range(12):
            if rotation[i]:
                self.set[face[i]] = ['A', 'B', 'C', 'D', 'E', 'F'][pi]

    def __str__(self):
        return str(self.set)

    def clone(self):
        c = Cube(self.faces, self.pieces)
        c.set = self.set[:]
        return c

    def count(self):
        c = 0
        for i in range(len(self.set)):
            if self.set[i]:
                c += 1
        return c

    def intersect(self, ri, pi, fi):
        """test if a given rotation, piece, face will interest with the
        current cube"""

        face = self.faces[fi]
        rotation = self.pieces[pi].get(ri)

        for i in range(12):
            if rotation[i] == 1 and self.set[face[i]] != 0:
                return True
        return False

class Stack:
    """list of currently chosen pieces for each face

    constructed as a stack so can pop back to a previous partial solution to
    attempt a different path.
    """

    def __init__(self):
        self.stack = []

    def append(self, entry):
        self.stack.append(entry)

    def pop(self):
        if len(self.stack):
            return self.stack.pop()
        return None

    def print_solution(self):
        l = ['A', 'B', 'C', 'D', 'E', 'F']
        f = [l[s.choice[1]] for s in self.stack]
        print " {} ".format(f[0])
        print "{}{}{}".format(f[1], f[2], f[3])
        print" {} ".format(f[4])
        print" {} ".format(f[5])

    def __str__(self):
        s = ""
        for state in self.stack:
            s += str(state.choice)
        return s

    def count(self):
        return len(self.stack)

def solve():
    """do the iteration to find the solution"""

    pieces = make_pieces()
    faces = make_faces()
    check_faces(faces)
    state = State(Cube(faces, pieces), range(6), range(4))
    state.set(0, 0, 0)
    stack = Stack()
    fi = 1
    while fi != 6 and state != None:
        ri, pi = state.next()
        while ri != None and pi != None:
            #print(state)
            #print "guess", (ri, pi, fi)
            if not state.cube.intersect(ri, pi, fi):
                s2 = state.clone()
                s2.set(ri, pi, fi)
                stack.append(state)
                state = s2
                print "choose", stack, state.choice
                #print state.cube
                #print state
                fi += 1
                if fi == 6:
                    stack.append(state)
                    stack.print_solution()
                    return True
            ri, pi = state.next()
        state = stack.pop()
        #if state:
        #    print "pop", state.choice
        #else:
        #    print "pop None"
        ##print state
        ##print("cube count:", state.cube.count())
        fi -= 1
    return False

print(__name__)

if __name__ == "__main__":
    if solve():
        print("solved!")
    else:
        print("not solved")
